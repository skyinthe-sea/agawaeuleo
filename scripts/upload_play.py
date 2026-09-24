#!/usr/bin/env python3
"""아가왜울어 — 이미 빌드된 AAB를 Play Console 트랙(기본 internal, `--track production` 가능)에 업로드.

cupplus `scripts/build_and_upload.py`의 업로드 절차(edits().insert →
bundles().upload → tracks().update → commit)를 그대로 따르되, **빌드는 하지
않는다**(호출 전에 `flutter build appbundle --release`가 끝나 있어야 함).

인증: cupplus 프로젝트의 Play Developer API 서비스계정 JSON을 재사용한다.
이 계정(`revenuecat-play-integration@cupplus-487101`)은 Play Console에서
`com.jiseosiyu.aga.agawaeuleo` 앱에 대한 권한을 이미 부여받았다.

사용:
    python3 scripts/upload_play.py
    python3 scripts/upload_play.py --track internal --sa /path/to/sa.json
    python3 scripts/upload_play.py --notes "이번 빌드 변경 요약"
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

ROOT = Path(__file__).resolve().parent.parent
AAB = ROOT / "build/app/outputs/bundle/release/app-release.aab"
PUBSPEC = ROOT / "pubspec.yaml"
PACKAGE_NAME = "com.jiseosiyu.aga.agawaeuleo"
DEFAULT_SA = Path.home() / "cupplus/oauth/cupplus-487101-085b3e121547.json"


def read_version() -> tuple[str, int]:
    """pubspec.yaml의 `version: X.Y.Z+N` → (X.Y.Z, N)."""
    text = PUBSPEC.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*([\d.]+)\+(\d+)\s*$", text, re.MULTILINE)
    if not m:
        sys.exit("pubspec.yaml에서 version을 찾지 못했습니다.")
    return m.group(1), int(m.group(2))


# 이용자가 마지막으로 받은 빌드 이후의 변경 요약(1.1.1+9 — 디자인 v3 "몽글 클레이" 전면 개편).
# 릴리스마다 갱신하거나 `--notes`로 덮어쓸 것 — 지난 빌드 문구가 그대로 올라가면
# 테스터가 무엇이 바뀌었는지 알 수 없다.
DEFAULT_NOTES = (
    "앱 분위기를 새로 단장했어요! 모든 증상 그림을 말랑말랑한 3D 클레이 아가 "
    "일러스트로 새로 그리고, 딸기우유처럼 포근한 색감과 동글동글한 글씨체로 "
    "화면 전체를 바꿨어요. 버튼과 카드도 더 둥글고 보기 편해졌고, "
    "앱 아이콘과 시작 화면의 아가도 새 모습으로 만나 보세요."
)


def upload(
    sa_json: Path,
    track: str,
    version_name: str,
    build_num: int,
    notes: str,
) -> None:
    if not AAB.exists():
        sys.exit(
            f"AAB가 없습니다: {AAB}\n"
            "먼저 `flutter build appbundle --release`를 실행하세요."
        )
    if not sa_json.exists():
        sys.exit(f"서비스계정 JSON이 없습니다: {sa_json}")

    size_mb = AAB.stat().st_size / 1024 / 1024
    print(f"업로드 대상: {AAB.name} ({size_mb:.1f}MB), 트랙={track}")

    creds = service_account.Credentials.from_service_account_file(
        str(sa_json),
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    service = build("androidpublisher", "v3", credentials=creds)

    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit["id"]

    media = MediaFileUpload(
        str(AAB), mimetype="application/octet-stream", resumable=True
    )
    bundle = (
        service.edits()
        .bundles()
        .upload(packageName=PACKAGE_NAME, editId=edit_id, media_body=media)
        .execute()
    )
    vc = bundle["versionCode"]
    print(f"AAB 업로드 완료 (versionCode={vc})")

    service.edits().tracks().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        track=track,
        body={
            "track": track,
            "releases": [
                {
                    "name": f"{version_name} ({build_num})",
                    "versionCodes": [str(vc)],
                    "status": "completed",
                    "releaseNotes": [{"language": "ko-KR", "text": notes}],
                }
            ],
        },
    ).execute()

    service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print(f"\n✅ 완료: {version_name}+{build_num} → Play '{track}' 트랙")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--track", default="internal")
    parser.add_argument("--sa", type=Path, default=DEFAULT_SA)
    parser.add_argument("--notes", default=DEFAULT_NOTES)
    args = parser.parse_args()

    name, num = read_version()
    upload(args.sa, args.track, name, num, args.notes)
