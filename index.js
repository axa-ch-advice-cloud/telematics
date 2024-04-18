import express from 'express';


const app = express();


app.route('/').get((req, res) => {
    res.send('Hello World!');
})

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log('Server is running on port 3000');
})

