
import {Request, Response} from 'express'
import axios, {AxiosError} from 'axios'
import dotenv from 'dotenv';
import {handleHttpError} from "../util/handleHttpError";
import {VehicleClearance} from "../classes/highMobilityClasses";
dotenv.config();


export async function getHighMobilityVehicleData(req: Request, res: Response) {
    try {
        const vin = req.params.vin
        const url: string = process.env.HM_API_URI + '/vehicle-data/autoapi-13/' + vin

        const response = await axios.get(url, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': req.headers.authorization
            },
        })
        res.status(200).json({...response.data})
        return

    }
    catch (e){
        const error = e as AxiosError
        const errorMessage = handleHttpError(error);
        res.status(error?.response?.status || 500).json({error: errorMessage})
        return
    }
}


export async function createClearance(req: Request, res: Response) {
    const url: string = process.env.HM_API_URI + '/fleets/vehicles'
    try {
        const vehicles = req.body as Array<VehicleClearance>

        if (!vehicles || !vehicles.length) {
            res.status(400).json({error: "Please include one or more vehicles (VIN + Brand) in the request body"})
            return
        }

        const response = await axios.post(url, {
            vehicles: vehicles
        },{
            headers: {
                'Content-Type': 'application/json',
                'Authorization': req.headers.authorization
            },
        })
        res.status(200).json({...response.data})
        return
    }
    catch (e){
        const error = e as AxiosError
        const errorMessage = handleHttpError(error);
        res.status(error?.response?.status || 500).json({error: errorMessage})
        return
    }
}

export async function getClearances(req: Request, res: Response) {
    const url: string = process.env.HM_API_URI + '/fleets/vehicles'
    try {
        const response = await axios.get(url, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': req.headers.authorization
            },
        })
        res.status(200).json({...response.data})
        return
    }
    catch (e){
        const error = e as AxiosError
        const errorMessage = handleHttpError(error);
        res.status(error?.response?.status || 500).json({error: errorMessage})
        return
    }

}


/*

Create Clearances Array needs to look like this:
 const vehicles = [
    {
        vin: "1HMV6FDK8GJ7F775C",
        brand: "sandbox",
        tags: {}
    },
    {
        vin: "1HMPPPTCGFE8Y85FP",
        brand: "sandbox",
        tags: {}
    },
    {
        vin: "1HMFOVKXVTBBTMJEL",
        brand: "sandbox",
        tags: {}
    },
    {
        vin: "1HM7P32DYXXTAGJJ4",
        brand: "sandbox",
        tags: {}
    },
    {
        vin: "1HMCR7PX7X1KX75GP",
        brand: "sandbox",
        tags: {}
    },
]
 */

/*
First Create a clearance for a vehicle (Requires VIN and brand)
Optional: Check clearance status using getClearances()
Get vehicle data for said vehicle using getVehicleData()
*/
//createClearance(vehicles)
//getClearances()
//getVehicleData("1HMV6FDK8GJ7F775C")
