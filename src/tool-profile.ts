export type ToolProfile = 'collaboration' | 'setup' | 'all';

export const COLLABORATION_TOOLS = new Set([
  'list_workspaces',
  'list_boards',
  'list_boards_in_workspace',
  'get_active_board_info',
  'get_lists',
  'get_cards_by_list_id',
  'get_my_cards',
  'get_card',
  'get_card_comments',
  'get_card_history',
  'get_recent_activity',
  'get_checklist_items',
  'get_checklist_by_name',
  'find_checklist_items_by_description',
  'get_acceptance_criteria',
  'get_board_members',
  'get_board_labels',
  'get_health',
  'set_active_board',
  'set_active_workspace',
  'add_list_to_board',
  'add_card_to_list',
  'update_card_details',
  'move_card',
  'add_comment',
  'update_comment',
  'create_checklist',
  'add_checklist_item',
  'update_checklist_item',
  'create_label',
  'attach_image_to_card',
  'attach_file_to_card',
  'attach_data_to_card',
  'attach_image_data_to_card',
  'download_attachment',
]);

export const SETUP_ADMIN_TOOLS = new Set([
  'create_board',
  'update_list',
  'update_list_position',
  'update_label',
]);

export const RESTRICTED_TOOLS = new Set([
  'archive_card',
  'archive_list',
  'delete_comment',
  'delete_checklist_item',
  'delete_label',
  'copy_card',
  'copy_checklist',
  'add_cards_to_list',
  'get_board_custom_fields',
  'update_card_custom_field',
  'assign_member_to_card',
  'remove_member_from_card',
  'get_health_detailed',
  'get_health_metadata',
  'get_health_performance',
  'perform_system_repair',
]);

export const KNOWN_TOOLS = new Set([
  ...COLLABORATION_TOOLS,
  ...SETUP_ADMIN_TOOLS,
  ...RESTRICTED_TOOLS,
]);

export function parseToolProfile(value: string | undefined): ToolProfile {
  if (!value || value.trim() === '') {
    return 'collaboration';
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === 'collaboration' || normalized === 'setup' || normalized === 'all') {
    return normalized;
  }

  throw new Error(
    `Invalid TRELLO_MCP_TOOL_PROFILE '${value}'. Expected collaboration, setup, or all.`
  );
}

export function parseBooleanEnv(value: string | undefined): boolean {
  return value?.trim().toLowerCase() === 'true';
}

export function getEnabledToolNames(
  profile: ToolProfile,
  restrictedToolsEnabled: boolean
): Set<string> {
  if (profile === 'all') {
    return new Set(KNOWN_TOOLS);
  }

  const enabled = new Set(COLLABORATION_TOOLS);
  if (profile === 'setup') {
    for (const tool of SETUP_ADMIN_TOOLS) {
      enabled.add(tool);
    }
  }

  if (restrictedToolsEnabled) {
    for (const tool of RESTRICTED_TOOLS) {
      enabled.add(tool);
    }
  }

  return enabled;
}
