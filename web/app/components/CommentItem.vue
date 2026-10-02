<template>
  <div class="comment-item" :class="{ 'is-reply': isReply }">
    <NuxtLink :to="`/profile/${comment.user.id}`" class="comment-avatar-link">
      <AvatarCircle :name="comment.user.name" :avatar-url="comment.user.avatar_url" :size="28" />
    </NuxtLink>
    <div class="comment-body-col">
      <div class="comment-meta">
        <NuxtLink :to="`/profile/${comment.user.id}`" class="comment-username">{{ comment.user.name }}</NuxtLink>
        <span class="comment-date">{{ formattedDate }}</span>
      </div>
      <p class="comment-text">{{ comment.body }}</p>

      <button v-if="!isReply" type="button" class="comment-reply-toggle" @click="replying = !replying">
        Reply
      </button>

      <div v-if="replying" class="comment-reply-composer">
        <CommentComposer
          :post-id="postId"
          :parent-comment-id="comment.id"
          placeholder="Write a reply…"
          @posted="onReplyPosted"
        />
      </div>

      <div v-if="!isReply && comment.replies.length" class="comment-replies">
        <CommentItem
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :post-id="postId"
          is-reply
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'
import CommentComposer from './CommentComposer.vue'

const props = withDefaults(defineProps<{ comment: Comment; postId: string; isReply?: boolean }>(), {
  isReply: false,
})

const emit = defineEmits<{ posted: [comment: Comment] }>()

const replying = ref(false)

const formattedDate = computed(() =>
  new Date(props.comment.inserted_at).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }),
)

function onReplyPosted(reply: Comment) {
  props.comment.replies.push(reply)
  replying.value = false
  emit('posted', reply)
}
</script>

<style scoped>
.comment-item {
  display: flex;
  gap: 10px;
  padding: 16px 0;
  border-bottom: 1px solid var(--color-border);
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-item.is-reply {
  padding: 12px 0 0;
  border-bottom: none;
}

.comment-body-col {
  flex: 1;
  min-width: 0;
}

.comment-meta {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 4px;
}

.comment-avatar-link {
  display: inline-flex;
  flex-shrink: 0;
}

.comment-username {
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-ink);
  text-decoration: none;
}

.comment-username:hover {
  text-decoration: underline;
}

.comment-date {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.comment-text {
  margin: 0 0 6px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--color-ink);
}

.comment-reply-toggle {
  background: none;
  border: none;
  padding: 0;
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

.comment-reply-composer {
  margin-top: 10px;
}

.comment-replies {
  margin-top: 8px;
  padding-left: 16px;
  border-left: 2px solid var(--color-accent-secondary);
}
</style>
