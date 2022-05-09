# NZSL Infrastructure

This repistory contains Terraform and other configuration files related to the
infrastructure for NZSL projects. At this stage, only
[signbank](https://github.com/odnzsl/NZSL-signbank) is Terraformed, but other
projects may be added over time.

The terraform configuration (see the .tf files in this repo) is the real source of truth for this infrastructure. This document aims to provide some helpful background information and general principles.

## Environments

NZSL applications have the following environments:

1. UAT
   - Testers and acceptance of new features
2. Production

Each environment has dedicated resources within our AWS account.

## AWS Regions

We use Sydney as a primary AWS region for hosting because

1. It is the geographically closest AWS region to New Zealand (so better latency etc.)
1. It has three AZs (Each AWS AZ is an isolated data center) giving us good opportunity for redundancy within the region if required.

## AWS Tagging

For easy management of resources and costs, all AWS resources are automatically tagged (by Terraform) with at least these tags:

1. Name - The name of the resource
1. Environment - The name of the environment
1. Client - The name of the client
1. Project - The name of the project
1. ProvisioningTool - the name of the tool used to provision this resource

## DNS

### Public DNS

- The primary DNS domain is `nzsl.nz` and is managed by Cloudflare.
- DNS records should be recorded and managed using the [Cloudflare Terraform provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs).

## Load balancers and HTTPS/TLS

- TLS will be terminated at the load balancer - Cloudflare in this case.
- Communication between Cloudflare and application servers, _should_ be via HTTPS.
- Applications should force SSL.

## Application servers

- Application serving will be handled by Heroku, a platform-as-a-service product by Salesforce.
- Application serving should use at minimum standard-1x dynos for production traffic.

## Databases

- Databases are PostgreSQL hosted in Heroku via addons

### Database backups

- Databases are automatically backed up by Heroku

## File storage

- All assets/files will be stored as objects on S3
- S3 automatically provides redundancy by replicating objects (a.k.a. "files" in our context) to multiple locations in the same region
- Server side encryption using S3 managed keys (SSE-S3) will be configured by default on all buckets so all uploaded files will be encrypted for storage on disk
  - S3 uses AES-256 as encryption algorithm
  - Full details of the encryption scheme are available at http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html
  - _Encrypted by default_ is set on on buckets to ensure that **all** uploaded files will be encrypted whether or not the project explicitly requires it.

## Email

- We use [Mailgun](https://mailgun.com) to send emails from the application.
- These emails include:
  - Notifications about various events
  - User invitations
  - Password resets, etc
- Access to Mailgun is via TLS encrypted SMTP connection

## Dependency monitoring

Ruby, Python and JS package dependencies are audited with [Bundler Audit](https://github.com/rubysec/bundler-audit),
[safety](https://pypi.org/project/safety/) and [npm audit](https://docs.npmjs.com/cli/audit) respectively. This auditing typically happens:

1. Whenever new code is pushed
2. Nightly as part of Ackama's in-house monitoring suite (results reported to Ackama ops team)

Projects perform a range of other automated checks depending on their specific languge, framework, and requirements.
