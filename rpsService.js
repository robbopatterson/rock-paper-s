const AWS = require("aws-sdk");
const dynamoDbClient = new AWS.DynamoDB.DocumentClient({ region: "us-west-2" });

const types = ['Rock', 'Paper', 'Scissors'];

const nameValidationError = (name) => name ? null : 'name is required';
const typeValidationError = (type) => {
    if (!type)
        return 'type is required'
    if (!types.includes(type))
        return `${type} is not a known type`
}

const setCurrentThrow = async (name, type) => {
    const putParams = {
        TableName: process.env.RPS_TABLE,
        Item: {
            pk: 'lastthrow',
            sk: 'lastthrow',
            name: name,
            type: type,
            expire_at: epochExpiryAfterHours(1)   // Anything older than 1 hour can be ignored
        }
    };
    await dynamoDbClient.put(putParams).promise();
}

const getLastThrowGetParams = () => {
    return {
        TableName: process.env.RPS_TABLE,
        Key: {
            pk: 'lastthrow',
            sk: 'lastthrow'
        }
    };
}

const getOutstandingThrow = async () => {
    return await dynamoDbClient.get(getLastThrowGetParams()).promise();
}

const deleteOutstandingThrow = async () => {
    return await dynamoDbClient.delete(getLastThrowGetParams()).promise();
}


const secondsSinceEpoch = () => {
    return Math.round(Date.now() / 1000);
}

const epochExpiryAfterHours = hours => secondsSinceEpoch() + hours * 60 * 60; // Add 3600 s/hr

exports.getThrowResponse = async (name, type) => {
    const validationError = nameValidationError(name) || typeValidationError(type);
    if (validationError) {
        throw new { message: validationError, statuscode: 400 };
    }
    const outstandingThrow = await getOutstandingThrow();
    if (outstandingThrow.Item) {
        const response = responsesMeVs[type][outstandingThrow.Item.type];
        await deleteOutstandingThrow();
        response.vsName = outstandingThrow.Item.name;
        return response;
    } else {
        await setCurrentThrow(name, type);
        return {
            isWinner: null,
            message: `${name} has thrown down.  Please waiting for opponent.`,
        };
    }
}

const responsesMeVs = {
    "Rock": {
        "Rock": { message: "Rock vs Rock it a tie", isWinner: null },
        "Paper": { message: "Paper covers Rock", isWinner: false },
        "Scissors": { message: "Rock smashes Scissors", isWinner: true }
    },
    "Paper": {
        "Rock": { message: "Paper covers Rock", isWinner: true },
        "Paper": { message: "Paper vs Paper it a tie", isWinner: null },
        "Scissors": { message: "Scissors cut Paper", isWinner: false }
    },
    "Scissors": {
        "Rock": { message: "Rock smashes Scissors", isWinner: false },
        "Paper": { message: "Scissors cut Paper", isWinner: true },
        "Scissors": { message: "Sizzors vs Sizzors it a tie", isWinner: null }
    }
}
