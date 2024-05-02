import express from 'express';
import morgan from 'morgan';
import helmet from 'helmet';
import cors from 'cors';

//  Get dot env
import dotenv from 'dotenv';
import {getAccessToken} from "./services/highMobilityService";
import {createClearance, getClearances, getVehicleData} from "./controllers/highMobilityController";
import {authenticateRequest} from "./controllers/authController";
dotenv.config();


const app = express();

app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());

app.route('/').get((req, res) => {
    res.send('Hello World!');
})

//app.get('/access-token', getAccessToken)

/**
 * To call these, you either need to include the High mobility access token as a Bearer token in Auth header,
 * or send our admin login as base64 and Basic auth
 */
app.get('/vehicle-data/:vin', authenticateRequest, getVehicleData)

app.get('/clearances', authenticateRequest, getClearances)

app.post('/clearances', authenticateRequest, createClearance)

export default app;