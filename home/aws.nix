{ env }:
{
  name = ".aws/config";
  value.text = ''
    [profile freckle]
    sso_start_url = ${env.AWS_SSO_URL}
    sso_region = us-east-1
    sso_account_id = ${env.AWS_ACCOUNT_ID_PROD}
    sso_role_name = Freckle-Prod-Engineers
    region = us-east-1

    [profile freckle-dev]
    sso_start_url = ${env.AWS_SSO_URL}
    sso_region = us-east-1
    sso_account_id = ${env.AWS_ACCOUNT_ID_DEV}
    sso_role_name = Freckle-Dev-Engineers
    region = us-east-1
  '';
}
