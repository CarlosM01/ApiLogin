from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
import os

import json

# Resolve DATABASE_URL dynamically
DATABASE_URL = os.getenv("DATABASE_URL")

# If DATABASE_URL is not set directly, try retrieving credentials from AWS Secrets Manager
if not DATABASE_URL:
    aws_secrets_name = os.getenv("AWS_SECRETS_NAME")
    if aws_secrets_name:
        try:
            import boto3

            region_name = os.getenv("AWS_REGION", "us-east-1")

            # 1. Fetch credentials from AWS Secrets Manager
            session = boto3.session.Session()
            client = session.client(
                service_name="secretsmanager", region_name=region_name
            )

            get_secret_value_response = client.get_secret_value(
                SecretId=aws_secrets_name
            )
            secret_data = json.loads(get_secret_value_response["SecretString"])
            db_user = secret_data.get("username")
            db_pass = secret_data.get("password")

            # 2. Determine host (check DB_HOST, or query CloudFormation if RDS_STACK_NAME is set)
            db_host = os.getenv("DB_HOST")
            rds_stack_name = os.getenv("RDS_STACK_NAME")

            if not db_host and rds_stack_name:
                cf_client = session.client(
                    service_name="cloudformation", region_name=region_name
                )
                cf_response = cf_client.describe_stacks(StackName=rds_stack_name)
                outputs = cf_response["Stacks"][0].get("Outputs", [])
                for output in outputs:
                    if output["OutputKey"] == "Endpoint":
                        db_host = output["OutputValue"]
                        break

            if not db_host:
                raise ValueError(
                    "DB_HOST environment variable or RDS_STACK_NAME is required when using AWS_SECRETS_NAME."
                )

            db_port = os.getenv("DB_PORT", "5432")
            db_name = os.getenv("POSTGRES_DB", os.getenv("DB_NAME", "logindb"))

            # 3. Construct DATABASE_URL
            DATABASE_URL = (
                f"postgresql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"
            )
        except Exception as e:
            print(f"Error resolving database connection via AWS Secrets Manager: {e}")
            raise e

# If DATABASE_URL is still not resolved, fallback to env-based Postgres credentials, or default SQLite
if not DATABASE_URL:
    db_user = os.getenv("POSTGRES_USER")
    db_pass = os.getenv("POSTGRES_PASSWORD")
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("POSTGRES_DB", "login_db")

    if db_user and db_pass and db_host:
        DATABASE_URL = f"postgresql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"
    else:
        DATABASE_URL = "sqlite:///./users.db"

engine = create_engine(
    DATABASE_URL,
    # check_same_thread=False is only needed for sqlite
    connect_args={"check_same_thread": False}
    if DATABASE_URL.startswith("sqlite")
    else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    """Dependency that provides a DB session and closes it after use."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
