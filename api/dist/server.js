"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const fs_1 = __importDefault(require("fs"));
const authorizer_1 = require("./authorizer");
const buffer = fs_1.default.readFileSync('config.json');
const configuration = JSON.parse(buffer.toString());
const app = (0, express_1.default)();
const authorizer = new authorizer_1.Authorizer(configuration);
app.set('etag', false);
app.use('/*', authorizer.validateJWT);
/*
 * A simple business endpoint to simulate creating a transaction
 */
app.post('/api/transactions', (request, response) => {
    const data = { message: 'Success response from the Example API' };
    response.setHeader('content-type', 'application/json');
    response.status(200).send(JSON.stringify(data, null, 2));
    console.log(`Example API returned a success result at ${new Date().toISOString()}`);
});
/*
 * For simplicity the example API uses an HTTP internal URL
 */
app.listen(configuration.port, () => {
    console.log(`Example API is listening on internal HTTP port ${configuration.port}`);
});
