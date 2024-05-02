
/*
loadData(), etc.
*/
import dotenv from 'dotenv';
dotenv.config()
import {Request, Response} from "express";
import axios, {AxiosError} from "axios";
import {handleHttpError} from "../util/handleHttpError";

export async function getCarusoVehicleData(req: Request, res: Response) {
    try {
        const vehicles = [...req.body].map((vin: string) => {
            return {
                identifier: {
                    type: "VIN",
                    value: vin
                }
            }
        })

        const requestBody = {
            version: '1.0',
            vehicles: vehicles,
            dataItems: [
                //'dtc', Gives error
                'dtcconfirmed',
                'mileage'
            ]
        }

        const url: string = process.env.CARUSO_API_URL + '/delivery/v1/in-vehicle';
        const subscriptionId = process.env.CARUSO_SUBSCRIPTION_ID;
        const apiKey = process.env.CARUSO_API_KEY;
        const response = await axios.post(url, requestBody,{
            headers: {
                'Content-Type': 'application/json',
                'X-Subscription-Id': subscriptionId,
                'X-API-Key': apiKey
            },
        })

        const vehicleData = {}
        const responseData = response?.data?.inVehicleData;
        for (const data of responseData) {
            // @ts-ignore need to create response Classes so ts doesnt complain
            vehicleData[data?.identifier?.value] = {...data.response}
        }
        res.status(200).json({...vehicleData})
        return

    }
    catch (e){
        const error = e as AxiosError

        // Caruso specific, incorrect data items
        if (error?.response?.status === 400) {
            // @ts-ignore
            const errorMessage = error?.response?.data?.reasonText;
            res.status(400).json({error:errorMessage })
        }

        const errorMessage = handleHttpError(error);
        res.status(error?.response?.status || 500).json({error: errorMessage})
        return
    }
}

