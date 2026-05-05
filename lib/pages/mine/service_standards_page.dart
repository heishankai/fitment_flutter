import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';

/// 工匠服务管理规范（偏蓝领阅读：较大字号、适中间距）
class ServiceStandardsPage extends StatelessWidget {
  const ServiceStandardsPage({super.key});

  static const double _docTitleSize = 21;
  static const double _sectionSize = 18;
  static const double _bodySize = 16.5;
  static const double _lineHeight = 1.55;

  TextStyle get _docTitleStyle => const TextStyle(
        fontSize: _docTitleSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: _lineHeight,
      );

  TextStyle get _sectionStyle => const TextStyle(
        fontSize: _sectionSize,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        height: _lineHeight,
      );

  TextStyle get _bodyStyle => const TextStyle(
        fontSize: _bodySize,
        height: _lineHeight,
        color: AppColors.textSubtitle,
      );

  TextStyle get _subBulletStyle => _bodyStyle;

  Widget _paragraph(String text, {double bottom = 12}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SelectableText(text, style: _bodyStyle),
    );
  }

  Widget _numberedLine(String text, {double bottom = 10}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SelectableText(text, style: _bodyStyle),
    );
  }

  Widget _subBullet(String text, {double bottom = 8}) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('· ', style: _subBulletStyle.copyWith(color: AppColors.primary)),
            Expanded(child: SelectableText(text, style: _subBulletStyle)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: SelectableText(title, style: _sectionStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        title: const Text('服务规范', style: TextStyle(fontSize: 18)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SelectableText(
                  '工匠服务管理规范',
                  textAlign: TextAlign.center,
                  style: _docTitleStyle,
                ),
              ),
              const SizedBox(height: 16),
              _paragraph(
                '为规范平台施工与服务标准，保障施工质量与服务质量，平台特制定本服务管理规范。请各工长、师傅认真学习并严格遵守，确保施工与服务的高品质、标准化输出，履行应尽职责。',
              ),
              _sectionTitle('一、工地形象规范'),
              _numberedLine(
                '1. 着装要求：施工现场必须穿着平台统一工作服，禁止穿拖鞋、光膀子。',
              ),
              _numberedLine(
                '2. 环境卫生：施工工地上不得有烟头。卫生间应保持清洁无异味，严禁随意大小便。',
              ),
              _numberedLine(
                '3. 材料堆放：材料须分类码放整齐，禁止混放；水泥、沙子必须袋装整齐，禁止散堆乱放。',
              ),
              _numberedLine(
                '4. 现场整洁：每日至少清扫一次，做到“人走场清”，无生活垃圾残留。',
              ),
              _numberedLine(
                '5. 成品保护：入户门、窗户、柜体、地面等须铺贴保护膜，要求齐整、牢固、无破损。',
              ),
              _numberedLine(
                '6. 标识清晰：厨卫墙面水电标识线须粘贴正确、齐全。',
              ),
              _sectionTitle('二、工地安全规范'),
              _numberedLine(
                '1. 离场管理：施工人员离开工地前必须关闭门窗、水电总阀，防止安全事故的发生。',
              ),
              _numberedLine('2. 施工安全：'),
              _subBullet('落地窗、栏杆拆除后须做好安全防护；'),
              _subBullet('施工梯子必须系好安全绳；'),
              _subBullet('临时用电须使用电缆，严禁使用花线或单股线。'),
              _subBullet('严禁使用明火，防止火灾事故。'),
              _numberedLine('3. 现场行为：'),
              _subBullet('禁止在工地住宿、做饭；'),
              _subBullet('禁止饮酒及酒后施工；'),
              _subBullet('禁止高空抛物。'),
              _numberedLine(
                '4. 合规施工：严禁私自承接项目，如违规拆除混凝土梁柱、承重墙，拆改燃气、采暖、消防设施等。',
              ),
              _numberedLine(
                '5. 消防设备：施工现场须配备有效灭火器，严禁使用过期或失效设备。',
              ),
              _numberedLine(
                '6. 行为规范：严禁在工地吵架、斗殴、赌博、酗酒等不良行为。',
              ),
              _sectionTitle('三、工匠行为规范'),
              _numberedLine(
                '1. 收费合规：严禁不按平台标准开单，包括乱收费、恶意加价、虚报数量或人工项目。',
              ),
              _numberedLine('2. 禁止线下交易：严禁引导业主进行线下交易。'),
              _numberedLine(
                '3. 工具自备：不得要求业主购买本应自备的施工工具或耗材（如切割片、电锤钻头等）。',
              ),
              _numberedLine(
                '4. 禁止提前收款：严禁在订单未完成前要求业主提前确认收货。',
              ),
              _numberedLine(
                '5. 旧料处理：不得擅自处理业主有回收价值的旧料（如废旧电线、旧门窗等）。',
              ),
              _numberedLine(
                '6. 禁止转包：严禁将平台项目转包给他人；接单人不在现场而由他人施工视为转包。',
              ),
              _numberedLine(
                '7. 材料管理：严禁盗窃、倒卖、挪用业主材料；不得故意破坏工地施工或材料。',
              ),
              _numberedLine('8. 诚信自律：'),
              _subBullet('严禁向工长或管理人员行贿；'),
              _subBullet('不得拒绝平台巡查、监督与管理。'),
              _numberedLine(
                '9. 账号规范：严禁工长将个人账号交由工匠登录进行巡查、验收或打卡。',
              ),
              _numberedLine(
                '10. 培训参与：工匠应积极参加平台培训，提升施工与服务技能。',
              ),
              _numberedLine(
                '11. 信息规范：工匠上传的头像、案例、个人主页等不得包含电话号码、微信、二维码等联系方式；不得发布色情、暴力、赌博、涉黑、不实信息等内容。',
              ),
              _numberedLine(
                '12. 工艺标准：必须按平台工艺标准施工，严重不符者立即停工停单。',
              ),
              _numberedLine(
                '13. 信息真实：须如实提交工地实景图片，严禁伪造施工现场或工艺信息。',
              ),
              _numberedLine(
                '14. 接单响应：接单后10分钟内须立即主动联系业主（23:00至次日8:00接单可于8:00后联系），严禁长时间不联系或失联。',
              ),
              _numberedLine(
                '15. 守时履约：严禁与业主确认服务时间后爽约或拒绝上门，严重者立即停工停单。',
              ),
              _numberedLine(
                '16. 进场检查：各工种进场前须检查排水管、地漏是否畅通，并拍照在app中上传，否则承担相应堵塞责任。',
              ),
              _sectionTitle('四、工匠服务规范'),
              _numberedLine(
                '1. 配合协调：积极配合业主、工长及平台的合理安排与整改要求。',
              ),
              _numberedLine(
                '2. 及时响应：须及时回复业主与平台信息，非特殊情况不得超过12小时不回复。',
              ),
              _numberedLine(
                '3. 工艺执行：严格按平台工艺标准施工，确保项目达到验收标准。',
              ),
              _numberedLine('4. 接单履约：抢单成功后不得拖延进场。'),
              _numberedLine(
                '5. 工期保障：不得因自身原因无故停工或延误工期。',
              ),
              _numberedLine(
                '6. 验收责任：工长须严格验收，确保无违反工艺的质量问题。',
              ),
              _numberedLine(
                '7. 信息保密：未经业主允许，不得泄露业主个人信息及资料（含图纸、效果图等）。',
              ),
              _numberedLine(
                '8. 衔接服务：工长应做好工地管理及业主与工匠的衔接协调，避免有效投诉。',
              ),
              _numberedLine(
                '9. 工具携带：工匠接单上门须携带必备工具（如卷尺、笔记本等），确保开单及时准确。',
              ),
              _numberedLine(
                '10. 验收工具：工长验收须携带必要工具，严禁未现场验收即操作APP。',
              ),
              _numberedLine(
                '11. 数量核实：工长须对施工数量进行验收核实，不得推诿。',
              ),
              _numberedLine(
                '12. 服务连贯：不得无合理理由拒绝同一房屋同一工种的后续服务（如水电预埋后拒绝安装）。',
              ),
              _numberedLine(
                '13. 材料清点：完工前须在APP上提交剩余材料清点记录。',
              ),
              _sectionTitle('五、售后规范'),
              _numberedLine(
                '1. 售后响应：严禁无正当理由拒绝处理售后问题。',
              ),
              _numberedLine(
                '2. 时效保障：须在规定时效内积极处理售中、售后事项。',
              ),
              _numberedLine(
                '3. 平台配合：应积极配合平台安排的售中、售后工作。',
              ),
              const SizedBox(height: 8),
              _paragraph(
                '本规范自发布之日起执行，平台有权根据实际情况对本规范进行修订与解释。请各位工长、工匠严格遵守，共同维护平台服务品质与品牌形象。',
              ),
              _paragraph(
                '如有疑问，请及时联系平台客服咨询。',
                bottom: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
