wget https://github.com/snowplow/igluctl/releases/download/0.11.3/igluctl_0.11.3.zip
unzip igluctl_0.11.3.zip
SUPER_API_KEY=$(aws secretsmanager get-secret-value --secret-id SNOWPLOW_IGLU_SUPER_API_KEY --query SecretString --output text)
sh igluctl static push ../cfg/schemas/com.patrick-cloud/sample_input/jsonschema/1-0-0 https://snowplow-iglu.patrick-cloud.com $SUPER_API_KEY
