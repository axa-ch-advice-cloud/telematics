/* Code that contains the logic for job where we check vehicle telematic data for all cars */


export async function loadVehicleData() {
    // Caruso data can be requested for multiple VINs at a time, but High Mobility requires one api call per VIN,
    // so we need separate arrays for caruso and HM vehicles
    const carusoVehicles = []
    const highMobilityVehicles: any = []

    // Send one big API call for caruso vehicles, and handle

    for (const vehicle of highMobilityVehicles) {
        try {
            // Try to send HM Api call, if successful, store the data
        }
        catch (e) {
            // If it fails, handle accordingly (store the error in a table, maybe schedule to retry)
        }
    }

}
