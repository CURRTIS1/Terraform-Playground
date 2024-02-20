def lambda_handler(event, context):
    return {"msg": "post received" , "body": event["body"]}, 200