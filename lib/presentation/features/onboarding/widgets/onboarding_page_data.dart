import 'package:flutter/material.dart';

/// §11.2 온보딩 한 장의 콘텐츠(아이콘 + 제목 + 본문).
class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// §11.2 온보딩 3장 고정 콘텐츠 — ① 증상으로 빠르게 찾기 ② 필요한 육아용품 바로 보기
/// ③ 수유·수면 기록까지.
const List<OnboardingPageData> onboardingPages = <OnboardingPageData>[
  OnboardingPageData(
    icon: Icons.manage_search_rounded,
    title: '증상으로 빠르게 찾기',
    body: '배앓이부터 발진까지, 궁금한 증상을 검색하면 필요한 정보를 바로 보여드려요.',
  ),
  OnboardingPageData(
    icon: Icons.shopping_bag_outlined,
    title: '필요한 육아용품 바로 보기',
    body: '증상에 맞는 육아용품을 미리 골라뒀어요. 지금 필요한 것만 빠르게 확인하세요.',
  ),
  OnboardingPageData(
    icon: Icons.nightlight_round,
    title: '수유·수면 기록까지',
    body: '수유, 수면, 배변까지 간편하게 기록하고 흐름을 한눈에 확인해요.',
  ),
];
