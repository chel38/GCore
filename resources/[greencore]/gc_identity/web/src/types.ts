export type IdentityState =
  | 'uninitialized'
  | 'loading'
  | 'registration_required'
  | 'registering'
  | 'email_verification_pending'
  | 'auth_verification_required'
  | 'authorized'
  | 'character_required'
  | 'character_selected'
  | 'ready'
  | 'error'
  | 'disconnecting'

export interface AccountDto {
  id: number
  email: string
  status: string
  createdAt: number
}

export interface CharacterDto {
  id: number
  firstName: string
  lastName: string
  createdAt: number
}

export interface IdentitySnapshot {
  protocolVersion: number
  state: IdentityState
  account: AccountDto | null
  characters: CharacterDto[]
  selectedCharacter: CharacterDto | null
  limits: { maxCharacters: number }
  passwordAuthentication: false
  verification?: {
    type: 'registration' | 'authentication'
    maskedEmail: string
    expiresIn: number
    resendIn: number
  } | null
}

export interface NuiResponse {
  ok: boolean
  requestId?: string
  code?: string
}

export type NuiMessage =
  | { type: 'snapshot'; payload: IdentitySnapshot }
  | { type: 'rejected'; payload: { code: string; requestId?: string } }
  | { type: 'lifecycleError'; payload: { code: string } }
  | { type: 'reset' }

export interface NuiBridge {
  invoke<TPayload extends object>(callback: string, payload: TPayload): Promise<NuiResponse>
}
