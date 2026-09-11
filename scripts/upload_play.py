#!/usr/bin/env python3
"""아가왜울어 — 이미 빌드된 AAB를 Play Console 내부 테스트 트랙에 업로드.

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


# 내부 테스터가 마지막으로 받은 빌드 이후의 변경 요약(1.1.0+7 — 홈·상세 전면 개편 + 먹 캡슐 탭바 + 스플래시).
# 릴리스마다 갱신하거나 `--notes`로 덮어쓸 것 — 지난 빌드 문구가 그대로 올라가면
# 테스터가 무엇이 바뀌었는지 알 수 없다.
DEFAULT_NOTES = (
    "홈과 증상 상세를 새로 만들었어요. "
    "홈에서는 증상을 한 장씩 넘겨 보며 추천 용품과 1위 제품을 바로 확인할 수 있고, "
    "증상 상세는 요약·병원 신호·돌보는 법·추천 용품으로 나눠 한 장씩 넘겨 봅니다. "
    "온보딩·시작 화면·하단 탭도 새로 단장했고, 육아 기록 기능은 잠시 숨겼어요."
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
