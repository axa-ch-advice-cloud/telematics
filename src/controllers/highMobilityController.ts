
import {Request, Response} from 'express'
import { getAccessToken } from "../services/highMobilityService";
import axios, {AxiosError} from 'axios'
import dotenv from 'dotenv';
dotenv.config();


export async function getVehicleData(req: Request, res: Response) {
    try {
        const vin = req.params.vin
        const url: string = process.env.HM_API_URI + '/vehicle-data/autoapi-13/' + vin

        const response = await axios.get(url, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': req.headers.authorization
            },
        })
        //console.log(response.data.diagnostics.odometer.data)
        //console.log(response.data)
        res.status(200).json({...response.data})
        return

    }
    catch (e){
        const error = e as AxiosError
        console.log(error)
        if (error?.response?.status === 403) {
            res.status(403).json({error:"No permission to access vehicle with this VIN, maybe you need to access clearance first"})
            return
        }
    }
    res.status(500).json({error:"Something went wrong"})
    return
}


async function createClearance(vehicles: Array<Object>) {
    const data = await getAccessToken()
    const url: string = process.env.HM_API_URI + '/fleets/vehicles'
    try {
        const response = await axios.post(url, {
            vehicles: vehicles
        },{
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + data.access_token
            },
        })
        console.log(response.data)
        return response.data
    }
    catch (e){
        console.log("ERROR", e)
    }
}


async function getClearances() {
    const data = await getAccessToken()
    const url: string = process.env.HM_API_URI + '/fleets/vehicles'
    try {
        const response = await axios.get(url, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + data.access_token
            },
        })
        console.log(response.data)
        return response.data
    }
    catch (e){
        console.log("ERROR", e)
    }
}



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
/*
First Create a clearance for a vehicle (Requires VIN and brand)
Optional: Check clearance status using getClearances()
Get vehicle data for said vehicle using getVehicleData()
*/
//createClearance(vehicles)
getClearances()
//getVehicleData("1HMV6FDK8GJ7F775C")
