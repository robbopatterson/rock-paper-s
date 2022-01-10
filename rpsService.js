const AWS = require("aws-sdk");
const dynamoDbClient = new AWS.DynamoDB.DocumentClient({ region: "us-west-2" });

const types = ['Rock','Paper','Scissors'];

const nameValidationError = (name) => name ? null : 'name is required';
const typeValidationError = (type) => {
  if (!type)
    return 'type is required'
  if ( !types.includes(type) )
    return `${type} is not a known type`
}

exports.getThrowResponse = async ( name, type ) => {
    const validationError = nameValidationError(name) || typeValidationError(type);
    if (validationError) {
      throw new {message: validationError, statuscode:400};
    }
    const putParams = {
        TableName: process.env.RPS_TABLE,
        Item : {
        pk: 'lastthrow',
        sk: 'lastthrow',
        name: name,
        type: type,
      }
    }
    await dynamoDbClient.put(putParams).promise();
    return {
      isWinner: null,
      message:`${name} has thrown down`
    };
}