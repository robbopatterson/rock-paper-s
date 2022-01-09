const { app } = require('./handler');
process.env.RPS_TABLE = 'dev-rps';

app.listen(3000, () => {
    console.log('listening at port 3000');
})
