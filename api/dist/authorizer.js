"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Authorizer = void 0;
const base64url_1 = __importDefault(require("base64url"));
const remote_1 = require("jose/jwks/remote");
const verify_1 = require("jose/jwt/verify");
const node_forge_1 = require("node-forge");
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
            response.status(401).send(JSON.stringify(error));
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
        const publicKeyHeader = request.header('x-example-client-public-key');
        if (publicKeyHeader) {
            return decodeURIComponent(publicKeyHeader);
        }
        return null;
    }
    /*
     * Verify that the public key received at runtime matches that in the JWT issued by the Authorization Server
     */
    verifyClientPublicKey(receivedPublicKey, jwtPayload) {
        const expectedThumbprint = this.getCertificateThumbprintFromJwt(jwtPayload);
        const receivedThumbprint = this.publicKeyCertToThumbprint(receivedPublicKey);
        console.log(expectedThumbprint);
        console.log(receivedThumbprint);
        if (expectedThumbprint !== receivedThumbprint) {
            throw new Error('The API request contained an invalid client certificate public key');
        }
    }
    /*
     * Get the client certificate asserted by the Authorization Server
     */
    getCertificateThumbprintFromJwt(jwtPayload) {
        const cnf = jwtPayload['cnf'];
        if (cnf) {
            const thumbprint = cnf['x5t#S256'];
            if (thumbprint) {
                return thumbprint;
            }
        }
        throw new Error('The JWT did not contain the expected cnf/x5t#S256 claim');
    }
    /*
     * Convert a public key to a SHA256 thumbprint, which is base64 url-encoded
     */
    publicKeyCertToThumbprint(publicKey) {
        const cert = node_forge_1.pki.certificateFromPem(publicKey);
        const derBytes = node_forge_1.asn1.toDer(node_forge_1.pki.certificateToAsn1(cert)).getBytes();
        const hexThumbprint = node_forge_1.md.sha256.create().update(derBytes).digest().toHex();
        return base64url_1.default.encode(Buffer.from(hexThumbprint, 'hex'));
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
