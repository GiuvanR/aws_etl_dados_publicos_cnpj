{
    "Comment": "A description of my state machine",
    "StartAt": "GetCNPJLastUpdate",
    "States": {
      "GetCNPJLastUpdate": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "Parameters": {
          "FunctionName": "arn:aws:lambda:us-east-1:598433695633:function:check-update-cnpj:$LATEST"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "GetTables",
        "ResultSelector": {
          "LambdaResult.$": "States.StringToJson($.Payload.body)"
        }
      },
      "GetTables": {
        "Type": "Task",
        "Next": "CheckIfTableExists",
        "Parameters": {
          "DatabaseName": "cnpj"
        },
        "Resource": "arn:aws:states:::aws-sdk:glue:getTables",
        "ResultPath": "$.Tables"
      },
      "CheckIfTableExists": {
        "Type": "Choice",
        "Choices": [
          {
            "Not": {
              "Variable": "$.Tables.TableList[0]",
              "IsPresent": true
            },
            "Next": "BuildLoopInput"
          }
        ],
        "Default": "GetTableLastPartition"
      },
      "GetTableLastPartition": {
        "Type": "Task",
        "Parameters": {
          "DatabaseName": "cnpj",
          "TableName": "empresas"
        },
        "Resource": "arn:aws:states:::aws-sdk:glue:getPartitions",
        "Next": "DownloadCNPJTest",
        "ResultSelector": {
          "partitionValues.$": "$.Partitions[*].Values"
        },
        "ResultPath": "$.partitionValues"
      },
      "DownloadCNPJTest": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "arn:aws:lambda:us-east-1:598433695633:function:downloadCNPJTest:$LATEST"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "DownloadTest",
        "ResultSelector": {
          "downloadTest.$": "$.Payload.body"
        },
        "ResultPath": "$.downloadTest"
      },
      "DownloadTest": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.downloadTest.downloadTest",
            "BooleanEquals": false,
            "Next": "Success"
          }
        ],
        "Default": "BuildLoopInput"
      },
      "BuildLoopInput": {
        "Type": "Pass",
        "Next": "Fetch Loop",
        "Parameters": {
          "files": [
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas0.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas1.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas2.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas3.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas4.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas5.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas6.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas7.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas8.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            },
            {
              "url": "https://dadosabertos.rfb.gov.br/CNPJ/Empresas9.zip",
              "table_name": "empresas",
              "date.$": "$.LambdaResult.ref_date"
            }
          ]
        }
      },
      "Success": {
        "Type": "Succeed"
      },
      "Fetch Loop": {
        "Type": "Map",
        "ItemProcessor": {
          "ProcessorConfig": {
            "Mode": "INLINE"
          },
          "StartAt": "Fetch file",
          "States": {
            "Fetch file": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "Parameters": {
                "Payload.$": "$",
                "FunctionName": "arn:aws:lambda:us-east-1:598433695633:function:fetch_cnpj_data:$LATEST"
              },
              "End": true
            }
          }
        },
        "InputPath": "$",
        "Next": "EmpresasCrawler",
        "ItemsPath": "$.files"
      },
      "EmpresasCrawler": {
        "Type": "Task",
        "End": true,
        "Parameters": {
          "Name": "CrawlerEmpresas"
        },
        "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler"
      }
    }
  }