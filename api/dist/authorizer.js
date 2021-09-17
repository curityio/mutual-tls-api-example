"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Authorizer = void 0;
const remote_1 = require("jose/jwks/remote");
const verify_1 = require("jose/jwt/verify");
class Authorizer {
    constructor(configuration) {
        this.configuration = configuration;
        this.validateJWT = this.validateJWT.bind(this);
    }
    /*
     * Perform extended JWT validation via a library
     */
    async validateJWT(request, response, next) {
        try {
            const accessToken = this.readAccessToken(request);
            if (!accessToken) {
                throw new Error('No access token was received in the incoming request');
            }
            const receivedPublicKey = this.getReceivedCertificatePublicKey(request);
            if (!receivedPublicKey) {
                throw new Error('No client certificate public key was received in the incoming request');
            }
            const remoteKeySet = (0, remote_1.createRemoteJWKSet)(new URL(this.configuration.jwksUrl));
            const options = {
                algorithms: [this.configuration.algorithm],
                issuer: this.configuration.issuer,
                audience: this.configuration.audience,
            };
            const result = await (0, verify_1.jwtVerify)(accessToken, remoteKeySet, options);
            this.verifyClientPublicKey(receivedPublicKey, result.payload);
            response.locals.claims = result.payload;
            next();
        }
        catch (e) {
            const statusCode = 401;
            this.logError(e, statusCode);
            const error = {
                code: 'unauthorized',
                message: 'Missing, invalid or expired access token',
            };
            response.status(401).send(JSON.stringify(error, null, 2));
        }
    }
    /*
     * Try to read the JWT access token provided by the API gateway
     */
    readAccessToken(request) {
        const authorizationHeader = request.header('authorization');
        if (authorizationHeader) {
            const parts = authorizationHeader.split(' ');
            if (parts.length === 2 && parts[0] === 'Bearer') {
                return parts[1];
            }
        }
        return null;
    }
    /*
     * Try to read the client certificate public key provided by the API gateway
     */
    getReceivedCertificatePublicKey(request) {
        const publicKey = request.header('x-example-client-public-key');
        if (publicKey) {
            return publicKey;
        }
        return null;
    }
    /*
     * Verify that the public key received at runtime matches that in the JWT issued by the Authorization Server
     */
    verifyClientPublicKey(receivedPublicKey, jwtPayload) {
        var _a;
        const expectedThumbprint = (_a = jwtPayload['cnf']) === null || _a === void 0 ? void 0 : _a['x5t#S256'];
        if (expectedThumbprint !== receivedPublicKey) {
            throw new Error('The API request contained an invalid client certificate public key');
        }
    }
    /*
     * Basic API error logging
     */
    logError(e, statusCode) {
        const details = e.message ? e.message : 'No further information provided';
        console.log(`API Problem Encountered, status: ${statusCode}, details: ${details}`);
    }
}
exports.Authorizer = Authorizer;