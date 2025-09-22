gcloud auth application-default login --scopes=https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform

ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
echo "$ACCESS_TOKEN"

FOLDER_ID="${1}" #google folder ID (take it from URL of folder in browser)
GOOGLE_PROJECT="${2}"

OUTPUT_DIR="${3:-output}"


script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
OUTPUT_DIR="$script_dir/$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"


#a js filter expression selecting files named ## - abc, where ## are 2 digits.
jq_filter='.files[]
  | select(.mimeType=="application/vnd.google-apps.document"
           and (.name | test("^[0-9]{2} - .+")))
  | [.id, .name] | @tsv'

file_list=$(
  curl -s -G \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"  \
    -H "X-Goog-User-Project: ${GOOGLE_PROJECT}" \
    --data-urlencode "q='${FOLDER_ID}' in parents and trashed=false" \
    --data-urlencode "pageSize=1000" \
    --data-urlencode "fields=nextPageToken,files(id,name,mimeType)" \
    "https://www.googleapis.com/drive/v3/files" \
  | jq -r "$jq_filter"
)

echo $file_list


# 2) Export every matching doc as PDF
#   - Make filename secure (replace / and : by _)

while IFS=$'\t' read -r id name; do
  [ -z "${id:-}" ] && continue
  safe_name="$(echo "$name" | tr '/:' '__')"
  out_path="${OUTPUT_DIR}/${safe_name}.pdf"
  echo "Eksporterer: $name  →  $out_path"
  curl -s -L \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Goog-User-Project: ${GOOGLE_PROJECT}" \
    "https://www.googleapis.com/drive/v3/files/${id}/export?mimeType=application/pdf" \
    -o "$out_path"
done <<< "$file_list"

