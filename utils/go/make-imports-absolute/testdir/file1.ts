import * as React from 'react';
import {
  SafeTrans,
  useSafeTranslation,
} from '@freckle/educator-materials/ts/helpers/translate';
import xor from 'lodash/xor';
import includes from 'lodash/includes';
import { fromJust } from '@freckle/maybe';
import map from 'lodash/map';
import uniq from 'lodash/uniq';
import some from 'lodash/some';
import filter from 'lodash/filter';
import find from 'lodash/find';
import { mmap, maybe } from '@freckle/maybe';
import { toggleMembership } from '@freckle/educator-entities/ts/common/helpers/common-helper';
import { Button } from '@freckle/educator-materials/ts/components/button';
import { Alert } from '@freckle/educator-materials/ts/components/alert';
import { DefaultByGradeT } from '@freckle/educator-entities/ts/common/models/default-by-grade';
import { getDashboardModesForGradeAndSubject } from '@freckle/educator-entities/ts/common/helpers/default-by-grade';
import { SchoolAttrs } from '@freckle/educator-entities/ts/roster/models/school';
import { PremiumLicensesAttrs } from '@freckle/educator-entities/ts/common/models/premium-licenses';
import { hasPremiumSubject } from '@freckle/educator-entities/ts/common/logic/premium-access';
import {
  DashboardModeT,
  DashboardModeSubjectT,
} from '@freckle/educator-entities/ts/common/helpers/dashboard-modes';
import {
  DashboardModes,
  sortDashboardModes,
} from '@freckle/educator-entities/ts/common/helpers/dashboard-modes';
import { filterBySubject } from '@freckle/educator-entities/ts/common/models/enabled-dashboard-modes';
import { StudentAttrs } from '@freckle/educator-entities/ts/users/models/student';
import { Spinner } from '@freckle/educator-entities/ts/common/components/spinner-wrapper/spinner';
import { TranslateT } from '@freckle/educator-entities/ts/common/helpers/translate';
import { HttpError } from '@freckle/educator-entities/ts/common/exceptions/http-error';
import { useSafeEffectExtraDeps } from '@freckle/react-hooks';
import isEqual from 'lodash/isEqual';
import { logError } from '@freckle/classroom/ts/common/helpers/exception-handlers/bugsnag-client';
import {
  updateStudentEnabledDashboardModes,
  revertStudentEnabledDashboardModes,
  updateCourseGradeEnabledDashboardModes,
  revertCourseGradeEnabledDashboardModes,
} from '@freckle/classroom/ts/common/helpers/api/dashboard-modes';
import { ClassroomTeacherAttrs } from '@freckle/classroom/ts/users/models/teacher';
import { UpdateStudentDashboardModal } from '@freckle/classroom/ts/roster/components/rosters/student-edit-page/subject-dashboard-settings/settings-form/update-student-dashboard-modal';
import { SettingsForm } from '@freckle/classroom/ts/roster/components/rosters/student-edit-page/subject-dashboard-settings/settings-form/settings-form';
import { DashboardPreview } from '@freckle/classroom/ts/roster/components/rosters/student-edit-page/subject-dashboard-settings/dashboard-preview';
import { QuoteRequestModalLink } from '@freckle/classroom/ts/common/components/quote-request-modal-link';
import NotificationManager from '@freckle/classroom/ts/common/components/notifications-wrapper/notification-manager';
import { Text } from '@freckle/educator-materials/ts/components/typography';

import { showErrorHandlerAndFail } from './../../../../../../common/routers/app-router';

import {
  settingsWrapper,
  premiumMessage,
  dashboardModeStyle,
  selectOptionsStyle,
  selectOptionsDisabled,
  settingsContainer,
  settingsFormContainer,
  settingsFooter,
  changesCopy,
  alertContainer,
} from './settings-form.module.scss';

function deriveState<SettingsState>(
  props: {
    currentDashboardModesForStudent: Array<DashboardModeT>;
    subject: DashboardModeSubjectT;
    initSettingsState: SettingsState;
  },
  hasChangedSettings: boolean = false
): State<SettingsState> {
  const { subject, currentDashboardModesForStudent, initSettingsState } = props;

  const enabledDashboardModes = filterBySubject(
    currentDashboardModesForStudent,
    subject
  );

  return {
    loading: false,
    enabledDashboardModes: sortDashboardModes(enabledDashboardModes),
    activeDashboardMode: null,
    hasChangedSettings,
    showConfirmModal: null,
    missingDashboardModeSettings: [],
    settingsState: initSettingsState,
  };
}

export type Props<SettingsState> = {
  courseId: number;
  currentDashboardModesForStudent: Array<DashboardModeT>;
  gradeDefaults: DefaultByGradeT;
  student: StudentAttrs;
  students: Array<StudentAttrs>;
  teacher: ClassroomTeacherAttrs;
  schools: Array<SchoolAttrs>;
  premiumLicenses: PremiumLicensesAttrs;
  subject: DashboardModeSubjectT;
  initSettingsState: SettingsState;
  saveSettingsChanges: (
    applyToClass: boolean,
    settingsState: SettingsState
  ) => Promise<null>;
  children: (
    state: SettingsState,
    isDashboardModeEnabled: (dashboardMode: DashboardModeT) => boolean,
    setMissingDashboardModeSettings: (
      dashboardMode: DashboardModeT,
      missing: boolean
    ) => void,
    updateState: (state: SettingsState) => void
  ) => React.ReactElement;
};

type State<SettingsState> = {
  loading: boolean;
  enabledDashboardModes: Array<DashboardModeT>;
  activeDashboardMode: DashboardModeT | null | undefined;
  hasChangedSettings: boolean;
  showConfirmModal: 'student' | 'class' | null | undefined;
  missingDashboardModeSettings: Array<DashboardModeT>;
  settingsState: SettingsState;
};

export function SettingsFormContainer<SettingsState>(
  props: Props<SettingsState>
): React.ReactElement {
  const { t } = useSafeTranslation();
  const initialStates = deriveState({
    subject: props.subject,
    currentDashboardModesForStudent: props.currentDashboardModesForStudent,
    initSettingsState: props.initSettingsState,
  });

  const [loading, setLoading] = React.useState<boolean>(initialStates.loading);
  const [enabledDashboardModes, setEnabledDashboardModes] = React.useState<
    Array<DashboardModeT>
  >(initialStates.enabledDashboardModes);
  const [activeDashboardMode, setActiveDashboardMode] = React.useState<
    DashboardModeT | null | undefined
  >(initialStates.activeDashboardMode);
  const [hasChangedSettings, setHasChangedSettings] = React.useState<boolean>(
    initialStates.hasChangedSettings
  );
  const [showConfirmModal, setShowConfirmModal] = React.useState<
    'student' | 'class' | null | undefined
  >(initialStates.showConfirmModal);
  const [missingDashboardModeSettings, setMissingDashboardModeSettings] =
    React.useState<Array<DashboardModeT>>(
      initialStates.missingDashboardModeSettings
    );
  const [settingsState, setSettingsState] = React.useState<SettingsState>(
    initialStates.settingsState
  );

  useSafeEffectExtraDeps<{ initialStates: State<SettingsState> }>(
    ({ initialStates }) => {
      setLoading(initialStates.loading);
      setEnabledDashboardModes(initialStates.enabledDashboardModes);
      setActiveDashboardMode(initialStates.activeDashboardMode);
      setShowConfirmModal(initialStates.showConfirmModal);
      setMissingDashboardModeSettings(
        initialStates.missingDashboardModeSettings
      );
      setSettingsState(initialStates.settingsState);
    },
    [],
    {
      initialStates: { value: initialStates, comparator: isEqual },
    }
  );

  function toggleDashboardMode(dashboardMode: DashboardModeT) {
    setEnabledDashboardModes((prevState) =>
      sortDashboardModes(toggleMembership(dashboardMode, prevState))
    );
    setHasChangedSettings(true);
  }

  function changeActiveDashboardMode(dashboardMode: DashboardModeT) {
    setActiveDashboardMode(dashboardMode);
  }

  function clearActiveDashboardMode() {
    setActiveDashboardMode(null);
  }

  function showConfirmModalForStudent() {
    setShowConfirmModal('student');
  }

  function showConfirmModalForClass() {
    setShowConfirmModal('class');
  }

  function hideConfirmModal() {
    setShowConfirmModal(null);
  }

  async function onConfirmChanges(applyToClass: boolean, t: TranslateT) {
    setLoading(true);
    setShowConfirmModal(null);
    setHasChangedSettings(false);
    try {
      await saveChanges(applyToClass);
      NotificationManager.create({
        title: t(
          'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SAVE_NOTIFICATION_TITLE'
        ),
        message: t(
          'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SAVE_NOTIFICATION_MESSAGE'
        ),
        timeOut: 7000,
      });
    } catch (e) {
      logError(new HttpError(e));
      showErrorHandlerAndFail(
        'Teacher',
        t('STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SAVE_FAILED')
      );
    } finally {
      setLoading(false);
    }
  }

  async function saveChanges(applyToClass: boolean): Promise<null> {
    const { saveSettingsChanges } = props;
    await Promise.all([
      saveDashboardModes(applyToClass),
      saveSettingsChanges(applyToClass, settingsState),
    ]);
    return null;
  }

  function saveDashboardModes(applyToClass: boolean): Promise<void> {
    const { courseId, gradeDefaults, student, subject } = props;
    const grade = student.grade;

    const defaultModesForSubject = getDashboardModesForGradeAndSubject(
      gradeDefaults,
      grade,
      subject
    );

    if (xor(enabledDashboardModes, defaultModesForSubject).length === 0) {
      // If the indicated modes are the same as defaults, perform a revert
      return applyToClass
        ? revertCourseGradeEnabledDashboardModes(
            courseId,
            subject,
            enabledDashboardModes,
            grade
          )
        : revertStudentEnabledDashboardModes(courseId, student.id, subject);
    } else {
      // Otherwise perform the put for the subject
      return applyToClass
        ? updateCourseGradeEnabledDashboardModes(
            courseId,
            subject,
            enabledDashboardModes,
            grade
          )
        : updateStudentEnabledDashboardModes(
            courseId,
            student.id,
            subject,
            enabledDashboardModes
          );
    }
  }

  function getDashboardModeText(t: TranslateT): string {
    const { student, subject, gradeDefaults } = props;
    const defaultModesForSubject = getDashboardModesForGradeAndSubject(
      gradeDefaults,
      student.grade,
      subject
    );

    if (xor(enabledDashboardModes, defaultModesForSubject).length === 0) {
      return t(
        'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SELECTED_PRACTICE_MODES_GRADE_DEFAULT_SELECTED',
        { grade: student.grade }
      );
    } else {
      return t(
        'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SELECTED_PRACTICE_MODES_SELECTED',
        {
          selectedCount: enabledDashboardModes.length,
        }
      );
    }
  }

  function selectAll() {
    const { subject } = props;
    setEnabledDashboardModes(
      sortDashboardModes(DashboardModes.getBySubject(subject))
    );
    setHasChangedSettings(true);
  }

  function selectDefaults() {
    const { gradeDefaults, student, subject } = props;
    setEnabledDashboardModes(
      getDashboardModesForGradeAndSubject(gradeDefaults, student.grade, subject)
    );
    setHasChangedSettings(true);
  }

  function onSettingsChange(settingsState: SettingsState) {
    setSettingsState(settingsState);
    setHasChangedSettings(true);
  }

  function isDashboardModeEnabled(dashboardMode: DashboardModeT): boolean {
    return some(enabledDashboardModes, (pMode) => pMode === dashboardMode);
  }

  function changeMissingDashboardModeSettings(
    dashboardMode: DashboardModeT,
    missing: boolean
  ) {
    setMissingDashboardModeSettings((missingDashboardModeSettings) => {
      if (missing) {
        return uniq(missingDashboardModeSettings.concat(dashboardMode));
      } else {
        return filter(
          missingDashboardModeSettings,
          (mode) => mode !== dashboardMode
        );
      }
    });
  }

  const {
    gradeDefaults,
    student,
    students,
    teacher,
    schools,
    premiumLicenses,
    subject,
    children,
  } = props;

  const starEnabled = maybe(
    () => false,
    (s) =>
      mmap((x) => x.starStatus === 'star_enabled', s.renaissanceSchoolClient),
    find(schools, (s) => s.id === teacher.schoolId)
  );

  if (loading) {
    return <Spinner />;
  }

  const quoteRequestLink = (
    <QuoteRequestModalLink
      linkText={t(
        'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_QUOTE_REQUEST_LINK_TEXT'
      )}
    />
  );
  const learnMoreQuoteRequestLink = (
    <QuoteRequestModalLink
      linkText={t(
        'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_LEARN_MORE_QUOTE_REQUEST_LINK_TEXT'
      )}
    />
  );

  const studentGrades = map(students, (s) => s.grade);

  const isMultiGradeClass = uniq(studentGrades).length > 1;

  const isPremium = hasPremiumSubject(premiumLicenses, subject);

  const premiumPopOver = (
    <SafeTrans
      i18nKey="STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_PREMIUM_POPOVER_CONTENT"
      components={{ quoteRequestLink }}
    />
  );

  const starPopOver = (subject: DashboardModeSubjectT) => (
    <SafeTrans
      i18nKey="STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_STAR_POPOVER_CONTENT"
      components={{ learnMoreQuoteRequestLink }}
      values={{ subject }}
    />
  );

  const [selectOptionsClassName, selectAllOnClick, selectDefaultsOnClick] =
    isPremium
      ? [selectOptionsStyle, selectAll, selectDefaults]
      : [selectOptionsDisabled, () => {}, () => {}];

  const selectedDashboardModeText = getDashboardModeText(t);

  const missingSettings = missingDashboardModeSettings.filter(
    isDashboardModeEnabled
  );

  const disableButtons =
    !hasChangedSettings ||
    enabledDashboardModes.length === 0 ||
    missingSettings.length > 0;

  const changesNode = isPremium ? (
    <div>
      <Text
        htmlElement="p"
        modifiers={['muted']}
        style="body-2"
        addClass={changesCopy}
      >
        {t(
          'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_CHANGES_NEXT_STUDENT_LOGIN_TEXT'
        )}
      </Text>
    </div>
  ) : null;

  const applyToAllText = isMultiGradeClass
    ? t(
        'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_APPLY_TO_ALL_MULTIPLE_GRADE_TEXT',
        {
          grade: student.grade,
        }
      )
    : t('STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_APPLY_TO_ALL_TEXT');

  const settingsFooterNode = isPremium ? (
    <div className={settingsFooter}>
      <Button
        style="secondary"
        onClick={showConfirmModalForClass}
        disabled={disableButtons}
        dataTest={`${subject}-save-for-all-button`}
      >
        {applyToAllText}
      </Button>
      <Button
        style="primary"
        onClick={showConfirmModalForStudent}
        disabled={disableButtons}
        dataTest={`${subject}-save-button`}
      >
        {t('STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_APPLY_SETTINGS_BUTTON')}
      </Button>
    </div>
  ) : (
    <p className={premiumMessage}>
      <SafeTrans
        i18nKey="STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_PREMIUM_MESSAGE"
        components={{ quoteRequestLink }}
      />
    </p>
  );

  const updateModal = (
    <UpdateStudentDashboardModal
      show={showConfirmModal !== null && showConfirmModal !== undefined}
      onHideModal={hideConfirmModal}
      onConfirm={(applyToClass) => {
        onConfirmChanges(applyToClass, t);
      }}
      applyToClass={showConfirmModal === 'class'}
      isMultiGradeClass={isMultiGradeClass}
      studentGrade={student.grade}
    />
  );

  const missingSettingsAlert =
    missingSettings.length === 0 ? null : (
      <div className={alertContainer}>
        <Alert type="danger">
          {t(
            'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_MISSING_SETTINGS_ALERT'
          )}
          <ul>
            {map(missingSettings, (setting) => (
              <li>
                {t(
                  'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_MISSING_SETTINGS_DASHBOARD_MODE_DISPLAY',
                  { setting }
                )}
              </li>
            ))}
          </ul>
        </Alert>
      </div>
    );

  const missingDashboardModeAlert =
    enabledDashboardModes.length === 0 ? (
      <div className={alertContainer}>
        <Alert type="danger">
          {t(
            'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_MISSING_DASHBOARD_MODE_ALERT_TEXT'
          )}
        </Alert>
      </div>
    ) : null;

  return (
    <>
      <div className={settingsWrapper}>
        <div className={dashboardModeStyle}>
          <p>
            <strong data-test={`${subject}-practice-mode-selection`}>
              {t(
                'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SELECTED_PRACTICE_MODES_TEXT',
                {
                  selectedDashboardModeText,
                }
              )}
            </strong>
          </p>
        </div>
        <div className={`${selectOptionsClassName} float-right`}>
          <ul>
            <li
              data-test={`${subject}-select-all-link`}
              onClick={selectAllOnClick}
            >
              {t(
                'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SELECT_ALL_LIST_ITEM'
              )}
            </li>
            <li
              data-test={`${subject}-select-defaults-link`}
              onClick={selectDefaultsOnClick}
            >
              {t(
                'STUDENT_EDIT_PAGE_SETTINGS_FORM_CONTAINER_SELECT_DEFAULTS_LIST_ITEM'
              )}
            </li>
          </ul>
        </div>
        <div className={settingsContainer}>
          <DashboardPreview
            student={student}
            dashboardModes={enabledDashboardModes}
            activeDashboardMode={activeDashboardMode}
          />
          <div className={settingsFormContainer}>
            <SettingsForm
              subject={subject}
              student={student}
              enabledDashboardModes={enabledDashboardModes}
              gradeDefaults={gradeDefaults}
              toggleDashboardMode={toggleDashboardMode}
              setActiveDashboardMode={changeActiveDashboardMode}
              clearActiveDashboardMode={clearActiveDashboardMode}
              maybeDisabledContent={(dashboardMode) => {
                const focusSkillsPracticeModes =
                  DashboardModes.focusSkillsPracticeModes();
                const isFocusSkillsPractice = includes(
                  focusSkillsPracticeModes,
                  dashboardMode
                );

                if (!isFocusSkillsPractice) {
                  return null; // /not/ disabled
                } else if (!isPremium) {
                  return premiumPopOver;
                } else if (!starEnabled) {
                  const mSubject =
                    DashboardModes.subjectFromMode(dashboardMode);

                  const subject = fromJust(
                    mSubject,
                    `Could not find DashboardModeSubjectT for DashboardModeT ${dashboardMode}`
                  );

                  return starPopOver(subject);
                }
              }}
            />
          </div>
        </div>
        {children(
          settingsState,
          isDashboardModeEnabled,
          changeMissingDashboardModeSettings,
          onSettingsChange
        )}
        {changesNode}
        {missingDashboardModeAlert}
        {missingSettingsAlert}
        {settingsFooterNode}
      </div>
      {updateModal}
    </>
  );
}
