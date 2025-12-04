"""Script to upload a model to Hugging Face Hub."""

from huggingface_hub import HfApi
from dotenv import load_dotenv

load_dotenv()

MODEL_PATH = "/mnt/disks/ssd/tulu3_8b_sft/tulu3_8b_sft__8__1764801713"
REPO_ID = "p-1-ai/tulu3-8b-sft-replicate"  # Change this to your desired repo name


def main():
    api = HfApi()

    print(f"Uploading model from: {MODEL_PATH}")
    print(f"To Hugging Face repo: {REPO_ID}")

    # Create the repo if it doesn't exist
    api.create_repo(repo_id=REPO_ID, exist_ok=True, repo_type="model")

    # Upload the entire folder
    api.upload_folder(
        folder_path=MODEL_PATH,
        repo_id=REPO_ID,
        commit_message="Upload tulu3 8b sft model",
    )

    print("Upload complete!")


if __name__ == "__main__":
    main()

