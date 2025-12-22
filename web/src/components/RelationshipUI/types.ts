export type RelationshipStatus = 'single' | 'pending' | 'dating' | 'engaged' | 'married';

export type RequestType = 'dating' | 'engagement' | 'marriage';

export interface Partner {
  id: string;
  name: string;
  avatar?: string;
  startDate: Date;
}

export interface PendingRequest {
  fromId: string;
  fromName: string;
  type: RequestType;
}

export interface RelationshipState {
  status: RelationshipStatus;
  partner?: Partner;
  pendingRequest?: PendingRequest;
}