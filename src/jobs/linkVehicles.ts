/*

Idea: Have a database table where we add vehicles (VIN | Provider (HM/Caruso) | Status (LINKED, UNLINKED, WAITING) ),
and we have a job that periodically checks the table for vehicles that are waiting to be added to our actual Vehicle table
(the one we use to actually run the getVehicleData API calls on either caruso or HM). If this job encounters a vehicle
that hasn't yet been added (Status is not "Added"), we have different Functions that are run to either add it to HM or Caruso,
once successfully added, we add the vehicle to the actual Vehicle Table and then mark its status in this table accordingly.

 Reason: For High Mobility, if you want to add a car you need to request Clearance first (createClearance),
 not sure how long it will take, so a table like mentioned above would make it much easier (maybe theres something
 similar for Caruso) and of course the job here would make sure that the Vehicle is only added to actual table once
 the Clearance has been accepted (GetClearances API)
 */

type UnlinkedVehicle = {
    vin: string;
    provider: string;
    status: string;
}

// Find vehicles in the table, that are waiting to be linked
function getUnlinkedVehicles() {
    // Just for the idea / example, should actually be searching through db table
    const unlinkedVehicles = [
        {
            vin: "WHSZ223SKMWSDF",
            provider: "high_mobility",
            status: "UNLINKED"
        }
    ]

    return unlinkedVehicles
}

// Is run with the unlinked vehicles found above (if any are found)
function handleVehicleLinking(vehicleList: Array<UnlinkedVehicle>) {
    for (const vehicle of vehicleList) {
        // For HM, means it's waiting for clearance, for Caruso ??? (maybe nothing or maybe other case)
        if (vehicle.status === "WAITING") {
            if (vehicle.provider === "high_mobility") {
                // Call getClearances API, if vehicle with this VIN is accepted, then set status to LINKED
                // and add vehicle to actual vehicles table, if clearance still waiting, do nothing, if clearance resulted
                // in an error do ??? (either send email or we add an ERROR status
            }
            else if (vehicle.provider === "caruso") {
                // Either nothing or something, depending on how caruso handles vehicle linking
            }
        }
        else if (vehicle.status === "UNLINKED") {
            if (vehicle.provider === "high_mobility") {
                // Call createClearance API using this vehicle, then set status to WAITING.
                // NOTE: createClearance requires the car brand, so we might need additional column
            }
            else if (vehicle.provider === "caruso") {
                // Call equivalent of caruso API, then, depending how they do stuff, set to WAITING or LINKED
            }
        }
        else {
            // ???
        }

    }
}


