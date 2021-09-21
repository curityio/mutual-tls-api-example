import express from 'express';
import fs from 'fs';
import https from 'https';
import {Authorizer} from './authorizer';
import {Configuration} from './configuration';

const buffer = fs.readFileSync('config.json');
const configuration = JSON.parse(buffer.toString()) as Configuration;
const app = express();

const authorizer = new Authorizer(configuration);
app.set('etag', false);
app.use('/api/*', authorizer.validateJWT);

/*
 * A simple business endpoint to simulate creating a transaction
 */
app.post('/api/transactions', (request: express.Request, response: express.Response) => {
    
    const data = {message: 'Success response from the Example API'};
    response.setHeader('content-type', 'application/json');
    response.status(200).send(JSON.stringify(data));

    console.log(`Example API returned a success result at ${new Date().toISOString()}`);
});

const pfxFile = fs.readFileSync(configuration.tlsCertificateFile);
const serverOptions = {
    pfx: pfxFile,
    passphrase: configuration.tlsCertificatePassword,
};

const httpsServer = https.createServer(serverOptions, app);
httpsServer.listen(configuration.port, () => {
    console.log(`Example API is listening on HTTPS port ${configuration.port}`);
});
