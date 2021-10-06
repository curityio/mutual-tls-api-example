import {NextFunction, Request, Response} from 'express';
import {createRemoteJWKSet} from 'jose/jwks/remote';
import {jwtVerify} from 'jose/jwt/verify';
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

            const remoteKeySet = createRemoteJWKSet(new URL(this.configuration.jwksUrl))

            const options = {
                algorithms: [this.configuration.algorithm],
                issuer: this.configuration.issuer,
                audience: this.configuration.audience,
            };
            
            const result = await jwtVerify(accessToken, remoteKeySet, options);

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
     * Basic API error logging
     */
    private logError(e: any, statusCode: number) {

        const details = e.message ? e.message : 'No further information provided';
        console.log(`API Problem Encountered, status: ${statusCode}, details: ${details}`);
    }
}
