import express from 'express';
import morgan from 'morgan';
import helmet from 'helmet';
import cors from 'cors';

//  Get dot env
import dotenv from 'dotenv';
import {getAccessToken} from "./services/highMobilityService";
import {getVehicleData} from "./controllers/highMobilityController";
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

app.get('/vehicle-data/:vin', authenticateRequest, getVehicleData)



export default app;