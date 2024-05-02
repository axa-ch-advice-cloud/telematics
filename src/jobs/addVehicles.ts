/*

Idea: Have a database table where we add vehicles (VIN | Provider (HM/Caruso) | Status (Added, Not Yet Added) ),
and we have a job that periodically checks the table for vehicles that are waiting to be added to our actual Vehicle table
(the one we use to actually run the getVehicleData API calls on either caruso or HM). If this job encounters a vehicle
that hasn't yet been added (Status is not "Added"), we have different Functions that are run to either add it to HM or Caruso,
once successfully added, we add the vehicle to the actual Vehicle Table and then mark its status in this table accordingly.

 Reason: For High Mobility, if you want to add a car you need to request Clearance first (createClearance),
 not sure how long it will take, so a table like mentioned above would make it much easier (maybe theres something
 similar for Caruso) and of course the job here would make sure that the Vehicle is only added to actual table once
 the Clearance has been accepted (GetClearances API)
 */

