import {
  formBindingData,
  FormExtensionAbility
} from '@kit.FormKit';
import { common, Want } from '@kit.AbilityKit';
import {
  addWidgetFormId,
  pushWidgetToForm,
  removeWidgetFormId
} from '../utils/WidgetSync';

const WARM_PAPER: string = '#FDF8F7';
const WARM_INK: string = '#282622';
const WARM_ACCENT: string = '#A65C4D';
const WARM_FAMILY: string = 'oneword_wenkai, serif';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    addWidgetFormId(this.context, formId);
    // 异步读取偏好后推送真实数据（避免与卡片创建竞态）
    setTimeout(() => {
      pushWidgetToForm(this.context, formId);
    }, 200);
    return formBindingData.createFormBindingData({
      'imgSrc': '',
      'content': '',
      'date': '',
      'paperColor': WARM_PAPER,
      'inkColor': WARM_INK,
      'accentColor': WARM_ACCENT,
      'fontFamily': WARM_FAMILY
    });
  }

  onUpdateForm(formId: string): void {
    pushWidgetToForm(this.context, formId);
  }

  onRemoveForm(formId: string): void {
    removeWidgetFormId(this.context, formId);
  }
}
