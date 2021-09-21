export interface Configuration {
    port: number;
    jwksUrl: string,
    algorithm: string;
    issuer: string;
    audience: string;
};
