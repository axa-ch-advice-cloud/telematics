import axios from 'axios';

export async function getAccessToken() {
  const url: string = process.env.HM_API_URI + '/access_tokens' || 'empty';
  const clientId = process.env.HM_CLIENT_ID;
  const clientSecret = process.env.HM_CLIENT_SECRET;
  try {
    const response = await axios.post(url, {
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret,
    }, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (response.data.access_token) {
      //console.log(response.data)
      return response.data;
    }

  } catch (e) {}
  return {
    error: 'Something went wrong',
  };
}
