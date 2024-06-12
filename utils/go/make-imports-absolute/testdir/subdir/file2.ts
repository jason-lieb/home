import { Moment } from 'moment-timezone';
import { ajaxJsonCall } from '@freckle/ajax';
import {
  ParserT,
  Parser,
  field,
  number,
  string,
  oneOf,
  array,
  boolean,
  nullable,
  date,
  record,
} from '@freckle/parser';
import { mapMaybes, maybe } from '@freckle/maybe';

import CApiHelper from '@freckle/educator-entities/ts/common/helpers/common-api-helper';
import { legacyWithCache } from '@freckle/educator-entities/ts/common/helpers/common-api-helper';
import {
  IdentityProviderT,
  parser as identityProviderParser,
} from '@freckle/educator-entities/ts/roster/identity-provider';

type StarStatus = 'star_enabled' | 'star_disabled' | 'star_unset';

const allStarStatuses: StarStatus[] = [
  'star_enabled',
  'star_disabled',
  'star_unset',
];

type RenaissanceSchoolClientT = {
  platform: string;
  clientId: string;
  rpid: string;
  baseUrl: string;
  starStatus: StarStatus;
  sharedRosteringEnabled: boolean;
};

export type SchoolAttrs = {
  id: number;
  name: string;
  createdAt: Moment;
  updatedAt: Moment;
  districtId: number;
  sisId: string | undefined | null;
  ncesSchoolId: string | undefined | null;
  cleverSchoolId: string | undefined | null;
  classLinkSchoolId: string | undefined | null;
  renaissanceRpIdentifier: string | undefined | null;
  city: string;
  administrativeArea: string | undefined | null;
  postalCode: string | undefined | null;
  formattedAddressLines: Array<string> | undefined | null;
  countryCode: string | undefined | null;
  pin: string | undefined | null;
  licenseUtilizationNotificationsMutedAt: Moment | undefined | null;
  courseSubjectsByLicensing: boolean;
  renaissanceSchoolClient: RenaissanceSchoolClientT | undefined | null;
  activeIdp: IdentityProviderT | undefined | null;
  syncIdp: boolean;
  crmId: string | undefined | null;
  active: boolean; // a school can be active/inactive in RL CRM. As that becomes our source-of-truth, we mirror that data.
  crmAccountNumber: number | undefined | null;
  identityProvider: IdentityProviderT | undefined | null;
  idpManaged: boolean;
};

const parseRenaissanceSchoolClient: ParserT<RenaissanceSchoolClientT> = record({
  platform: string(),
  clientId: string(),
  rpid: string(),
  baseUrl: string(),
  starStatus: oneOf<StarStatus>('StarStatus', allStarStatuses),
  sharedRosteringEnabled: boolean(),
});

const parseSchoolAttrs: ParserT<SchoolAttrs> = record({
  id: number(),
  name: string(),
  createdAt: field(date(), 'created-at'),
  updatedAt: field(date(), 'updated-at'),
  districtId: field(number(), 'district-id'),
  sisId: field(nullable(string()), 'sis-id'),
  ncesSchoolId: field(nullable(string()), 'nces-school-id'),
  cleverSchoolId: field(nullable(string()), 'clever-school-id'),
  classLinkSchoolId: field(nullable(string()), 'class-link-school-id'),
  renaissanceRpIdentifier: field(
    nullable(string()),
    'renaissance-r-p-identifier'
  ),
  city: string(),
  administrativeArea: field(nullable(string()), 'administrative-area'),
  postalCode: field(nullable(string()), 'postal-code'),
  formattedAddressLines: field(
    nullable(array(string())),
    'formatted-address-lines'
  ),
  countryCode: field(nullable(string()), 'country-code'),
  pin: nullable(string()),
  licenseUtilizationNotificationsMutedAt: field(
    nullable(date()),
    'license-utilization-notifications-muted-at'
  ),
  courseSubjectsByLicensing: field(boolean(), 'course-subjects-by-licensing'),
  renaissanceSchoolClient: field(
    nullable(parseRenaissanceSchoolClient),
    'renaissance-school-client'
  ),
  activeIdp: field(nullable(identityProviderParser), 'active-idp'),
  syncIdp: field(boolean(), 'sync-idp'),
  crmId: field(nullable(string()), 'crm-id'),
  active: field(boolean(), 'active'),
  crmAccountNumber: field(nullable(number()), 'crm-account-number'),
  identityProvider: field(
    nullable(identityProviderParser),
    'identity-provider'
  ),
  idpManaged: field(boolean(), 'idp-managed'),
});

export const parseSchool = Parser.mkRun<SchoolAttrs>(parseSchoolAttrs);

const parseSchools = Parser.mkRun<Array<SchoolAttrs>>(array(parseSchoolAttrs));

export function schoolHasSharedRostering(schoolAttrs: SchoolAttrs): boolean {
  return maybe(
    () => false,
    (client) => client.sharedRosteringEnabled,
    schoolAttrs.renaissanceSchoolClient
  );
}

// Subtype to support DetailedSchoolT, BasicSchoolT, etc used in Console:
type SchoolRenaissanceSchoolClientFieldsT = Inexact<{
  renaissanceSchoolClient: RenaissanceSchoolClientT | undefined | null;
}>;

export const schoolHasStarIntegration = (
  schoolAttrs: SchoolRenaissanceSchoolClientFieldsT
): boolean =>
  schoolAttrs.renaissanceSchoolClient?.starStatus === 'star_enabled';

export function getActiveIdps(
  schools: Array<SchoolAttrs>
): Set<IdentityProviderT> {
  return new Set(mapMaybes(schools, (school) => school.activeIdp));
}

export async function fetchSchoolsNoCache(): Promise<Array<SchoolAttrs>> {
  const url = CApiHelper.fancyPaths.v2.schools._();
  const response = await ajaxJsonCall({
    url,
    method: 'GET',
  });
  return parseSchools(response);
}

export const fetchSchools = legacyWithCache(fetchSchoolsNoCache);

export async function fetchSchool(id: number): Promise<SchoolAttrs> {
  const url = CApiHelper.fancyPaths.v2.schools.school._(id);
  const response = await ajaxJsonCall({
    url,
    method: 'GET',
  });
  return parseSchool(response);
}

export async function fetchSchoolsInDistrict(
  districtId?: number | null
): Promise<Array<SchoolAttrs>> {
  if (districtId !== null && districtId !== undefined) {
    const url = CApiHelper.fancyPaths.v2.districts.district.schools(districtId);
    const response = await ajaxJsonCall({
      url,
      method: 'GET',
    });
    return parseSchools(response);
  } else {
    return Promise.resolve([]);
  }
}
