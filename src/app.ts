import express from 'express';
import morgan from 'morgan';
import helmet from 'helmet';
import cors from 'cors';
import cron from 'node-cron'

// Load env variables
import dotenv from 'dotenv';
dotenv.config();

import {createClearance, getClearances, getVehicleData} from "./controllers/highMobilityController";
import {authenticateRequest} from "./controllers/authController";
import {vehicleLinkingJob} from "./jobs/linkVehicles";


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


cron.schedule('0 */2 * * *', () => {
    //console.log('Running the Vehicle Linking Job (Ran every 2 Hours)')
    vehicleLinkingJob()
})


export default app;