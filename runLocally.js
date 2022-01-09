const { app } = require('./handler');
process.env.PORTFOLIO_TABLE = 'dev-portfolio';

app.listen( 3000, () => {
    console.log('listening at port 3000');
})
