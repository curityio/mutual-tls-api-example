"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const fs_1 = __importDefault(require("fs"));
const https_1 = __importDefault(require("https"));
const authorizer_1 = require("./authorizer");
const buffer = fs_1.default.readFileSync('config.json');
const configuration = JSON.parse(buffer.toString());
const app = (0, express_1.default)();
const authorizer = new authorizer_1.Authorizer(configuration);
app.set('etag', false);
app.use('/api/*', authorizer.validateJWT);
/*
 * A simple business endpoint to simulate creating a transaction
 */
app.post('/api/transactions', (request, response) => {
    const data = { message: 'Success response from the Example API' };
    response.setHeader('content-type', 'application/json');
    response.status(200).send(JSON.stringify(data));
    console.log(`Example API returned a success result at ${new Date().toISOString()}`);
});
const pfxFile = fs_1.default.readFileSync(configuration.tlsCertificateFile);
const serverOptions = {
    pfx: pfxFile,
    passphrase: configuration.tlsCertificatePassword,
};
const httpsServer = https_1.default.createServer(serverOptions, app);
httpsServer.listen(configuration.port, () => {
    console.log(`Example API is listening on HTTPS port ${configuration.port}`);
});
