import {AxiosError} from "axios";

export function handleHttpError(error: AxiosError) {
    // If the API call went through, but didn't return a 200
    if (error.response) {
        switch (error.response.status) {
            case 404:
                return "Not found."
            case 403:
                return "Access Forbidden, make sure you are correctly authenticating."
            case 407:
                return "Proxy Error"
            default:
                return "Something went wrong"
        }
    }
    else if (error.request) {
        return "No response received"
    }
    else {
        return "Failed to sent request"
    }
}