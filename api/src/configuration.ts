export interface Configuration {
    port: number;
    tlsCertificateFile: string;
    tlsCertificatePassword: string;
    jwksUrl: string,
    algorithm: string;
    issuer: string;
    audience: string;
};
