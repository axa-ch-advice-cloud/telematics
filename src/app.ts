import express from 'express';
import morgan from 'morgan';
import helmet from 'helmet';
import cors from 'cors';

//  Get dot env
import dotenv from 'dotenv';
dotenv.config();


const app = express();

app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());

app.route('/').get((req, res) => {
    res.send('Hello World!');
})


export default app;