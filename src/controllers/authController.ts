import { Request, Response } from 'express';
import { getAccessToken } from '../services/highMobilityService';


export async function authenticateRequest(req: Request, res: Response, next: any) {
  try {
    const authHeader = req.headers.authorization || '';
    // If API call contains bearer token (meaning that the user sent High Mobility access token themselves,
    // send it
    if (authHeader.includes('Basic ') && atob(authHeader.split(' ')[1]) === 'upto:admin_password') {
      const response = await getAccessToken();
      req.headers.authorization = 'Bearer ' + response.access_token;
    } else if (!authHeader.includes('Bearer')) {
      res.status(403).json({ message: 'No permission, either send the admin login using basic auth or send the High Mobility access token yourself (in headers)' });
      return;
    }
    next();

  } catch (e) {
    console.log(e);
    res.status(500).json({ message: 'Something went wrong' });
  }

}