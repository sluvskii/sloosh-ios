use crate::{internal_error, not_found, success, with_cors};
use crate::services::cdn::{get_player_data, resolve_cdn_id_by_kp, PlayerData};
use vercel_runtime::{Response, ResponseBody};
use serde::Serialize;

#[derive(Serialize)]
struct StreamResponse {
    title: String,
    initial_m3u8: String,
    initial_season: u32,
    initial_episode: u32,
    episodes: Vec<crate::services::cdn::EpisodeJs>,
    is_series: bool,
}

impl From<PlayerData> for StreamResponse {
    fn from(data: PlayerData) -> Self {
        Self {
            title: data.title,
            initial_m3u8: data.initial_m3u8,
            initial_season: data.initial_season,
            initial_episode: data.initial_episode,
            episodes: data.episodes,
            is_series: data.is_series,
        }
    }
}

pub async fn handle_stream(cdn_id: u64, season: Option<u32>, episode: Option<u32>) -> Response<ResponseBody> {
    let data = match get_player_data(cdn_id, season, episode).await {
        Ok(d) => d,
        Err(e) if e.contains("not found") || e.contains("no episodes") || e.contains("no video") => {
            return with_cors(not_found("video not found"));
        }
        Err(_) => return with_cors(internal_error()),
    };

    let resp: StreamResponse = data.into();
    with_cors(success(resp))
}

pub async fn handle_stream_by_kp(kp_id: u64, season: Option<u32>, episode: Option<u32>) -> Response<ResponseBody> {
    let cdn_id = match resolve_cdn_id_by_kp(kp_id).await {
        Ok(id) => id,
        Err(_) => return with_cors(not_found("video not found")),
    };
    handle_stream(cdn_id, season, episode).await
}
