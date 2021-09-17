import express from 'express';
import fs from 'fs';
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
    response.status(200).send(JSON.stringify(data, null, 2));

    console.log(`Example API returned a success result at ${new Date().toISOString()}`);
});

/*
 * For simplicity the example API uses an HTTP internal URL
 */
app.listen(configuration.port, () => {
    console.log(`Example API is listening on internal HTTP port ${configuration.port}`);
});
