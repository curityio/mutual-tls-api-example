export interface Configuration {
    port: number;
    jwksUrl: string,
    algorithm: 'RS256';
    issuer: '';
    audience: '';
};
