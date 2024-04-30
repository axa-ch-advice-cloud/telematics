import { response } from "express"
import https from "https"
// this is needed for default trusted list of CAs
import tls from "tls"
// for reading files
import fs from "fs"

import axios from 'axios'
//  Get dot env
import dotenv from 'dotenv';
dotenv.config();

export async function getAccessToken() {
    const url: string = process.env.HM_TOKEN_URI || 'empty'
    const clientId = process.env.HM_CLIENT_ID
    const clientSecret = process.env.HM_CLIENT_SECRET
    try {
        const response = await axios.post(url, {
            "grant_type": "client_credentials",
            "client_id": clientId,
            "client_secret": clientSecret
        }, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        console.log("SUCCESS", response.data);
    } catch (e) {
        console.log("ERROR", e);
    }
}

getAccessToken()