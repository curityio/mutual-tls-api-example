import {NextFunction, Request, Response} from 'express';
import {createRemoteJWKSet} from 'jose/jwks/remote';
import {jwtVerify, JWTPayload} from 'jose/jwt/verify';
import {asn1, md, pki} from 'node-forge';
import {Configuration} from './configuration';

export class Authorizer {

    private readonly configuration: Configuration;

    public constructor(configuration: Configuration) {
        this.configuration = configuration;
        this.validateJWT = this.validateJWT.bind(this);
    }

    /*
     * Perform extended JWT validation via a library
     */
    public async validateJWT(request: Request, response: Response, next: NextFunction): Promise<void> {

        try {

            const accessToken = this.readAccessToken(request);
            if (!accessToken) {
                throw new Error('No access token was received in the incoming request')
            }

            const receivedPublicKey = this.getReceivedCertificatePublicKey(request);
            if (!receivedPublicKey) {
                throw new Error('No client certificate public key was received in the incoming request')
            }

            const remoteKeySet = createRemoteJWKSet(new URL(this.configuration.jwksUrl))

            const options = {
                algorithms: [this.configuration.algorithm],
                issuer: this.configuration.issuer,
                audience: this.configuration.audience,
            };
            
            const result = await jwtVerify(accessToken, remoteKeySet, options);
            this.verifyClientPublicKey(receivedPublicKey, result.payload);

            response.locals.claims = result.payload;
            next();

        } catch (e: any) {

            const statusCode = 401;
            this.logError(e, statusCode);

            const error = {
                code: 'unauthorized',
                message: 'Missing, invalid or expired access token',
            }
            response.status(401).send(JSON.stringify(error));
        }
    }

    /*
     * Try to read the JWT access token provided by the API gateway
     */
    private readAccessToken(request: Request): string | null {

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
    private getReceivedCertificatePublicKey(request: Request): string | null {

        const publicKeyHeader = request.header('x-example-client-public-key');
        if (publicKeyHeader) {
            return decodeURIComponent(publicKeyHeader)
        }

        return null;
    }

    /*
     * Verify that the public key received at runtime matches that in the JWT issued by the Authorization Server
     */
    private verifyClientPublicKey(receivedPublicKey: string, jwtPayload: JWTPayload): void {

        const expectedThumbprint = this.getCertificateThumbprintFromJwt(jwtPayload);
        const receivedThumbprint = this.publicKeyCertToThumbprint(receivedPublicKey);
        if (expectedThumbprint !== receivedThumbprint) {
            throw new Error('The API request contained an invalid client certificate public key');
        }
    }

    /*
     * Get the client certificate asserted by the Authorization Server
     */
    private getCertificateThumbprintFromJwt(jwtPayload: JWTPayload): string {

        const cnf = jwtPayload['cnf'] as any;
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
    private publicKeyCertToThumbprint(publicKey: string): string {

        const cert = pki.certificateFromPem(publicKey);
        const derBytes = asn1.toDer(pki.certificateToAsn1(cert)).getBytes();
        const hexThumbprint = md.sha256.create().update(derBytes).digest().toHex();
        const base64 = Buffer.from(hexThumbprint, 'hex').toString('base64');
        return base64.replace(/\+/g, '-').replace('/', '_').replace(/=+$/, '');
    }

    /*
     * Basic API error logging
     */
    private logError(e: any, statusCode: number) {

        const details = e.message ? e.message : 'No further information provided';
        console.log(`API Problem Encountered, status: ${statusCode}, details: ${details}`);
    }
}
