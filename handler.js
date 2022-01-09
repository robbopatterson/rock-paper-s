'use strict';

const express = require('express')
const app = express()
const cors = require('cors');
const serverless = require("serverless-http");
const AWS = require("aws-sdk");
const dynamoDbClient = new AWS.DynamoDB.DocumentClient({ region: "us-west-2" });

app.use(cors());
app.use(express.json()) // for parsing application/json

app.get('/:entity/:id', async function (req, res) {
  const params = {
    TableName: process.env.RPS_TABLE,
    Key: { pk: req.params.entity, sk: req.params.id },
  };

  try {
    const record = await dynamoDbClient.get(params).promise();
    if (record && record.Item) {
      res.json(record.Item.payload);
    } else {
      res.status(404).json({ message: 'Record not found' });
    }
  } catch (err) {
    res.status(500).json({ message: 'Unexpected exception', err });
  }
})

app.get('/:entity', async function (req, res) {
  const params = {
    TableName: process.env.RPS_TABLE,
    KeyConditionExpression: "#pk = :pk",
    ExpressionAttributeNames: {
      "#pk": "pk"
    },
    ExpressionAttributeValues: {
      ":pk": req.params.entity
    }
  };

  try {
    const record = await dynamoDbClient.query(params).promise();
    if (record && record.Items) {
      const response = record.Items.map(i => i.payload);
      res.json(response);
    } else {
      res.status(404).json({ message: 'Records not found' });
    }
  } catch (err) {
    res.status(500).json({ message: 'Unexpected exception', err });
  }
})

app.use((req, res, next) => {
  console.error('no match found for request', req);
  return res.status(404).json({
    error: `No matching API found`,
  });
});

module.exports.httpHandler = serverless(app);
module.exports.app = app;

