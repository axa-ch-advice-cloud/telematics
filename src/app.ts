import express from 'express';
import morgan from 'morgan';
import helmet from 'helmet';
import cors from 'cors';
import cron from 'node-cron'

// Load env variables
import dotenv from 'dotenv';
dotenv.config();

if (process.env.NODE_ENV === "production") {
    const result = require("dotenv").config({ path: ".env.production" });
    process.env = {
        ...process.env,
        ...result.parsed,
    };
}



import {createClearance, getClearances, getHighMobilityVehicleData} from "./controllers/highMobilityController";
import {authenticateRequest} from "./controllers/authController";
import {vehicleLinkingJob} from "./jobs/linkVehicles";
import {getCarusoVehicleData} from "./controllers/carusoController";


const app = express();

app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());

app.route('/').get((req, res) => {
    res.send('Hello World!');
})



// Send an array of VINs in body
app.get('/caruso/vehicle-data', getCarusoVehicleData)


/**
 * To call these, you either need to include the High mobility access token as a Bearer token in Auth header,
 * or send our admin login as base64 and Basic auth
 */
// Send a single vin as param
app.get('/hm/vehicle-data/:vin', authenticateRequest, getHighMobilityVehicleData)

app.get('/hm/clearances', authenticateRequest, getClearances)

app.post('/hm/clearances', authenticateRequest, createClearance)


cron.schedule('0 */2 * * *', () => {
    //console.log('Running the Vehicle Linking Job (Ran every 2 Hours)')
    vehicleLinkingJob()
})


export default app;