/***************
* IAM POLICIES *
***************/
// Import https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider.html
import {
  to = aws_iam_openid_connect_provider.github_actions
  id = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = { Name = "GHA" }
  tags_all       = { Name = "GHA" }
}

// GHA STS Assume Role Policy
resource "aws_iam_role" "static_gha_role" {
  name = var.gha_role_name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud":"sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub":[
              "repo:${var.repo_owner}/${var.repo_name1}:ref:refs/heads/staging",
              "repo:${var.repo_owner}/${var.repo_name1}:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })

  tags = var.tags
}


// GHA Assumed IAM Policy 
/*
resource "aws_iam_policy" "static_gha_policy" {
  name        = "static-gha-policy"
  description = "gha access policy to S3 buckets"
  policy      = data.aws_iam_policy_document.static_gha_role_policy_doc.json
}
*/

resource "aws_iam_role_policy" "static_gha_role_policy" {
  name       = "static-gha-role-policy"
  role       = aws_iam_role.static_gha_role.name
  policy = data.aws_iam_policy_document.static_gha_role_policy_doc.json
}

data "aws_iam_policy_document" "static_gha_role_policy_doc" {
  version = "2012-10-17"

  statement {
    sid = "ghas3staticsites"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "cloudfront:CreateInvalidation"
    ]

    effect = "Allow"
/*
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${aws_iam_role.static_gha_role.name}"]
    }
*/
    resources = [
      "${aws_s3_bucket.static_bucket.arn}*",
      "${aws_s3_bucket.static_bucket.arn}/*",
      "${aws_s3_bucket.static_bucket_staging.arn}*",
      "${aws_s3_bucket.static_bucket_staging.arn}/*",
      "${aws_cloudfront_distribution.static_distribution.arn}",
      "${aws_cloudfront_distribution.static_distribution_staging.arn}"
    ]
  }

 /* statement {
    sid = "gha-cloudfront-static-sites"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${aws_iam_role.static_gha_role.name}"]
    }

    resources = [
      "${aws_cloudfront_distribution.static_distribution.arn}"
    ]
  }*/
}


/*********************
* S3 BUCKET POLICIES *
*********************/
// Prod
resource "aws_s3_bucket_policy" "static_bucket_policy" {
  bucket = aws_s3_bucket.static_bucket.id
  policy = data.aws_iam_policy_document.static_bucket_policy.json
}

data "aws_iam_policy_document" "static_bucket_policy" {
  statement {
    sid    = "AllowCloudfrontAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = [
      "${aws_s3_bucket.static_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${var.account_id}:distribution/${aws_cloudfront_distribution.static_distribution.id}"]
    }
  }
}

// Staging
resource "aws_s3_bucket_policy" "static_bucket_policy_staging" {
  bucket = aws_s3_bucket.static_bucket_staging.id
  policy = data.aws_iam_policy_document.static_bucket_policy_staging.json
}

data "aws_iam_policy_document" "static_bucket_policy_staging" {
  statement {
    sid    = "AllowCloudfrontAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = [
      "${aws_s3_bucket.static_bucket_staging.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${var.account_id}:distribution/${aws_cloudfront_distribution.static_distribution_staging.id}"]
    }
  }
}
