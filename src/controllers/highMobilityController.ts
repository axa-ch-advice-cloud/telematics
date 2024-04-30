
/*
loadData(), etc.
*/

import { getAccessToken } from "../services/highMobilityService";

const HMKit = require('hmkit')


const hmkit = new HMKit(
    "c2JveAHq/+s9c1GHrYL6PP3F4JkzuMphhjxmVZGBI71Lv8efDHvlGlTbpmc6iA+9nZvn1rw9b4D6BSdgVt3BtGahGJcPocytLGfoaWBMWrhQv/ryy3oCn8eDYRm26B5rcz6A3kmegddIvCY2h1aN5DC139ltLFbEWlcuykqudV6xNDKwaDLRbe8JXGSUVkIvMDeROazxeyxd",
    "VyFiswafim93aLxkRk/sGieF0pHsOqTHhrlU1InAhZE="
  );



  




export async function getAccessCertificate() {
    await getAccessToken()

    //const accessCertificate = await hmkit.downloadAccessCertificate('b55af95a-607c-47e8-ad37-5016a8beda61')


}
